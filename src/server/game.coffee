uuid = Npm.require 'node-uuid'
md5 = Npm.require 'md5'


###
Main DotD server-side logic, unrelated to general
functioning of data socket
###
@Game = {}


###
Room container, indexed by primary identifier (name?).
Since we don't persist any of the game state to MongoDB,
any room not present in this container can be presumed
not to exist.
###
Game.rooms = {}


###
Game constants.
###
Game.constants =
    ticksPerSecond: 20
    loopIterationDelayMs: 2


class Game.State

    ###
    Generic states. Generally a 'stateful' object starts
    out as "STOPPED", turns "ACTIVE" and can
    be "PAUSED" if need be.
    ###

    @STOPPED = 0
    @PAUSED = 1
    @ACTIVE = 2


class Game.Identifiable

    ###
    Base class for objects which should contain
    instance-specific identifiers.
    ###

    ###
    "Unique" ID of this object.
    ###
    _id: null

    ###
    Constructor.
    ###
    constructor: () ->
        @_id = md5 uuid.v1()


class Game.Event extends Game.Identifiable

    ###
    Game base event.
    ###

    @type: 'base'


class Game.TickEvent extends Game.Event

    ###
    Game tick event.
    ###

    @type: 'tick'


class Game.Loggable extends Game.Identifiable

    ###
    Base class for objects which should be able to produce
    instance-specific logs.
    ###

    ###
    Log a message.
    ###
    log: (args...) ->
        args[0] = "[#{@constructor.name}:#{@_id.substr(0, 8)}] " + args[0]
        console.log.apply console.log, args

    ###
    Log a message.
    ###
    @log: (args...) ->
        args[0] = "[#{@name}] " + args[0]
        console.log.apply console.log, args

    ###
    Constructor.
    ###
    constructor: () ->
        super

        @log "Instantiating"


class Game.StartStoppable extends Game.Loggable

    ###
    Base class for things which can be started or stopped.
    ###

    ###
    Current state.

    Only modify with `setState` to avoid breakage.
    ###
    state: Game.State.STOPPED

    ###
    Start the instance.
    ###
    start: () ->
        @log "Starting"
        @state = Game.State.ACTIVE

    ###
    Stop the instance.
    ###
    stop: () ->
        @log "Stopping"
        @state = Game.State.STOPPED


class Game.Level extends Game.Loggable

    ###
    Level. A level has a difficulty, a size.
    ###

    ###
    Size. An array containing width, length and height.

    @type array<integer, integer, integer>
    ###
    size: [0, 0, 0]

    ###
    {@inheritDoc}
    ###
    constructor: (@size) ->
        super


class Game.Room extends Game.Loggable

    ###
    Room. A room contains a map, several players and so on
    and so forth.
    ###

    ###
    ID.
    ###
    id: null

    ###
    Name.
    ###
    name: null

    ###
    Current state.

    Only modify with `setState` to avoid breakage.
    ###
    state: Game.State.STOPPED

    ###
    Current players.

    Only modify with `addPlayer` and `removePlayer` to avoid breakage.
    ###
    players: {}

    ###
    The current room level.
    ###
    level: null

    ###
    The primary difficulty setting.

    Only modify with `setDifficulty` to avoid breakage.
    ###
    difficulty: 1

    ###
    Constructor.
    ###
    constructor: (@id, @name) ->
        super

        @log "Creating room '#{@name}' with ID '#{@id}'"
        Game.rooms[@id] = @

        @level = new Game.Level [32, 32, 16]

    ###
    Set the primary difficulty.

    Calling this method will also trigger a recalculation
    of other linked settings.
    ###
    setDifficulty: (difficulty) ->
        @difficulty = difficulty

    ###
    Set the state.
    ###
    setState: (state) ->
        @state = state

    ###
    Set the level.
    ###
    setLevel: (level) ->
        @level = level

    ###
    Add a player.
    ###
    addPlayer: (player) ->
        @log "Adding player '#{player.name}'"
        @players[player.id] = player

    ###
    Find a player by its primary identifier.
    ###
    findPlayer: (playerId) ->
        @log "Looking up player '#{playerId}'"
        @players[playerId]


    ###
    Remove a player.
    ###
    removePlayer: (player) ->
        @log "Removing player '#{player.name}'"
        delete @players[player.id]

    ###
    Find a room by its primary identifier.
    ###
    @find: (roomId) ->
        @log "Looking up room '#{roomId}'"
        Game.rooms[roomId]

    ###
    Attempt to remove a room.
    ###
    @remove: (room) ->
        @log "Removing room '#{room.name}'"
        delete Game.rooms[room.name]


class Game.Entity extends Game.Loggable

    ###
    Game entity. Can be rendered on the map.
    ###

    ###
    Positional coordinates.

    @type array<integer, integer, integer>
    ###
    position: [0, 0, 0]

    ###
    Positional history.

    @type array<array<integer, integer, integer>>
    ###
    positionHistory: []

    ###
    Directional vector.

    @type array<integer, integer, integer>
    ###
    direction: [0, 0, 0]


class Game.Player extends Game.Entity

    ###
    Game player. Has an ID, a name, a score and a color.
    ###

    ###
    ID.
    ###
    id: null

    ###
    Name.
    ###
    name: null

    ###
    Constructor.
    ###
    constructor: (@id, @name) ->
        super

        @log "Creating player '#{@name}' with ID '#{@id}'"


class Game.EventManager extends Game.StartStoppable

    ###
    Game event manager. In charge of running the main
    event loop, triggering periodic ticks and the like.
    ###

    ###
    Event queue.
    ###
    events: []

    ###
    Event handlers.
    ###
    handlers: {}

    ###
    {@inheritDoc}
    ###
    start: () ->
        super

        @loopForever()

    ###
    Perform a single iteration of the event loop,
    handling all events currently in the event queue.
    ###
    loop: () ->
        while event = @events.shift()
            @handle event

    ###
    Perform iterations of the event loop until
    this instance is stopped.

    @see `stop`
    @see `loop`
    ###
    loopForever: () ->
        @loop()

        if @state == Game.State.ACTIVE
            setTimeout () =>
                @loopForever()
            , Game.constants.loopIterationDelayMs

    ###
    Handle a single event.
    ###
    handle: (event) ->
        if @handlers[event.constructor.type]
            for handler in @handlers[event.constructor.type]
                result = handler event

                if result == false
                    break

    ###
    Dispatch a single event, placing it at the end of the event queue.
    ###
    dispatch: (event) ->
        @events.push event

    ###
    Register an event handler.
    ###
    addHandler: (event, handler) ->
        if not @handlers[event.type]
            @handlers[event.type] = []

        @handlers[event.type].push handler


class Game.PhysicsEngine extends Game.StartStoppable

    ###
    Game physics engine. In charge of processing
    positional updates, detecting collisions, etc.
    ###

    ###
    Handle a tick event.
    ###
    onTick: (event) =>
        # For each room, increment the current server tick counter
        # Once we reach the required amount of server ticks for a room
        # tick, we reset the counter.
        for id, room of Game.rooms
            room.tickCounter ?= 0
            room.tickCounter += 1

            if room.tickCounter >= (Game.constants.ticksPerSecond / room.difficulty)
                room.tickCounter = 0
                @onRoomTick event, room

    ###
    Handle a room tick.
    ###
    onRoomTick: (event, room) ->
        for id, player of room.players
            oldPosition = player.position[..]
            position = player.position
            direction = player.direction

            # Increment x, y and z positioning by direction
            # vector value
            for i in [0 .. 2]
                position[i] += direction[i]

                # Reset axis position when exceeding level
                # axis size
                if position[i] < 0
                    position[i] = room.level.size[i]
                else if position[i] > room.level.size[i]
                    position[i] = 0

            player.positionHistory.pop()
            player.positionHistory.unshift oldPosition


###
When a player joins a room,
create a room object if it doesn't yet exist.
Add the player to the room they've joined.
###
Game.onPlayerRoomJoin = (playerData, roomName) ->
    room = Game.Room.find roomName

    if not room
        room = new Game.Room roomName, roomName

    player = room.findPlayer playerData.id

    if not player
        player = new Game.Player playerData.id, playerData.name

    room.addPlayer player


###
When a player leaves a room,
remove them from the room they're leaving
and remove the room entirely if they were the
last player.
###
Game.onPlayerRoomLeave = (playerData, roomName) ->
    room = Game.Room.find roomName

    if room
        player = room.findPlayer playerData.id

        if player
            room.removePlayer player

    if not room.players.length
        Game.Room.remove room


###
When a player sends input to a room,
perform different actions depending on the type
of input.
###
Game.onPlayerRoomInput = (playerData, roomName, type, data) ->
    room = Game.Room.find roomName

    if room
        player = room.findPlayer playerData.id

    # @TODO Implement further


###
Start main game loop.
###
Game.events = new Game.EventManager
Game.events.start()

Game.physics = new Game.PhysicsEngine
Game.events.addHandler Game.TickEvent, Game.physics.onTick
Game.physics.start()


###
Trigger a 'tick' periodically.
###
setInterval () ->
    Game.events.dispatch new Game.TickEvent
, 1000 / Game.constants.ticksPerSecond
