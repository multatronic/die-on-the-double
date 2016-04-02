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


class Game.Loggable extends Game.Identifiable

    ###
    Base class for objects which should be able to produce
    instance-specific logs.
    ###

    log: (args...) ->
        args[0] = "[#{@constructor.name}:#{@_id.substr(0, 8)}] " + args[0]
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


class Game.Level

    ###
    Level. A level has a difficulty, a size.
    ###

    ###
    Width

    @type integer
    ###
    width: null

    ###
    Height

    @type integer
    ###
    height: null


class Game.Room

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
        console.log "Creating room '#{@name}' with ID '#{@id}'"
        Game.rooms[@id] = @

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
        console.log "Adding player '#{player.name}' to room '#{@name}'"
        @players[player.id] = player

    ###
    Find a player by its primary identifier.
    ###
    findPlayer: (playerId) ->
        console.log "Looking up player '#{playerId}'"
        @players[playerId]

    ###
    Remove a player.
    ###
    removePlayer: (player) ->
        console.log "Removing player '#{player.name}' from room '#{@name}'"
        delete @players[player.id]

    ###
    Find a room by its primary identifier.
    ###
    @find: (roomId) ->
        console.log "Looking up room '#{roomId}'"
        Game.rooms[roomId]

    ###
    Attempt to remove a room.
    ###
    @remove: (room) ->
        console.log "Removing room '#{room.name}'"
        delete Game.rooms[room.name]


class Game.Entity extends Game.Loggable

    ###
    Game entity. Can be rendered on the map.
    ###

    ###
    Positional coordinates.
    ###
    position: [0, 0]

    ###
    Positional history.
    ###
    position_history: []

    ###
    Directional vector.
    ###
    direction: [0, 0]


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
        console.log "Creating player '#{@name}' with ID '#{@id}'"


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
    Delay inbetween loops triggered by
    `loop_forever`, in ms.

    @type integer
    @see `loop_forever`
    ###
    loop_delay: 5

    ###
    {@inheritDoc}
    ###
    start: () ->
        super

        @loop_forever()

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
    loop_forever: () ->
        @loop()

        if @state == Game.State.ACTIVE
            setTimeout () =>
                @loop_forever()
            , @loop_delay

    ###
    Handle a single event.
    ###
    handle: (event) ->
        if @handlers[event.type]
            for handler in @handlers[event.type]
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
    add_handler: (event, handler) ->
        if not @handlers[event.type]
            @handlers[event.type]

        @handlers[event.type].push handler

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


###
Trigger a 'tick' periodically.
###
setInterval () ->
    Game.events.dispatch 'tick'
, 1000
