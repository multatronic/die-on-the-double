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


class Game.ClientType

    ###
    Client types.
    ###

    @PLAYER = 'player'
    @DISPLAY = 'display'


class Game.Identifiable

    ###
    Base class for objects which should contain
    instance-specific identifiers.
    ###

    ###
    "Unique" ID of this object.
    ###
    id: null

    ###
    Constructor.
    ###
    constructor: () ->
        @id ?= md5 uuid.v1()


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
        args[0] = "[#{@constructor.name}:#{@id.substr(0, 8)}] " + args[0]
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
    Room. A room contains a level, clients, entities and so on
    and so forth.
    ###

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
    Current clients.

    Only modify with `addClient` and `removeClient` to avoid breakage.
    ###
    clients: {}

    ###
    Current entities.

    Only modify with `addEntity` and `removeEntity` to avoid breakage.
    ###
    entities: {}

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
    Add a client.
    ###
    addClient: (client) ->
        @log "Adding client '#{client.name}'"
        @clients[client.id] = client

    ###
    Find a client by its primary identifier.
    ###
    findClient: (clientId) ->
        @log "Looking up client '#{clientId}'"
        @clients[clientId]

    ###
    Remove a client.
    ###
    removeClient: (client) ->
        @log "Removing client '#{client.name}'"
        delete @clients[client.id]

    ###
    Add an entity.
    ###
    addEntity: (entity) ->
        @log "Adding entity '#{entity.id}'"
        @entities[entity.id] = entity

    ###
    Find an entity by its primary identifier.
    ###
    findEntity: (entityId) ->
        @log "Looking up entity '#{entityId}'"
        @entities[entityId]

    ###
    Remove an entity.
    ###
    removeEntity: (entity) ->
        @log "Removing entity '#{entity.id}'"
        delete @entities[entity.id]

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
        delete Game.rooms[room.id]


class Game.Client extends Game.Loggable

    ###
    Game client. Can optionally be linked to a
    game entity.
    ###

    ###
    Name.

    @type string
    ###
    name: null

    ###
    Type.

    @type integer
    @see `Game.ClientType`
    ###
    type: null

    ###
    {@inheritDoc}
    ###
    constructor: (@id, @name, @type) ->
        super


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


class Game.SnakeEntity extends Game.Entity

    ###
    Snake entity. The position is used as the
    snake's front. Everything else is part of the position history.
    ###


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
        for id, entity of room.entities
            oldPosition = entity.position[..]
            position = entity.position
            direction = entity.direction

            # Increment x, y and z positioning by direction
            # vector value
            for i in [0 .. 2]
                position[i] += direction[i]

                # Reset axis position when exceeding level
                # axis size
                if position[i] < 0
                    position[i] = room.level.size[i] - 1
                else if position[i] > (room.level.size[i] - 1)
                    position[i] = 0

            entity.positionHistory.unshift oldPosition
            entity.positionHistory.pop()


###
When a client joins a room,
create a room object if it doesn't yet exist.
Create a new client object and add it to the room
as well. In the case of a player joining,
create a new entity and link it to the client.
###
Game.onRoomJoin = (clientData, roomName) ->
    room = Game.Room.find roomName

    if not room
        room = new Game.Room roomName, roomName
        Game.rooms[room.id] = room

    client = room.findClient clientData.id

    if not client
        client = new Game.Client clientData.id, clientData.name, clientData.type

        # If this client is a player, create a player entity
        # and link the client and the player entity
        if clientData.type == Game.ClientType.PLAYER
            entity = new Game.SnakeEntity
            client.entity = entity
            room.addEntity entity

        room.addClient client


###
When a client leaves a room,
remove them from the room they're leaving
and remove the room entirely if they were the
last client. If they had a linked entity,
remove said entity as well.
###
Game.onRoomLeave = (clientData, roomName) ->
    room = Game.Room.find roomName

    if room
        client = room.findClient clientData.id

        if client
            # If this client has a linked entity (eg. due to being a player),
            # remove that entity from the room as well
            if client.entity
                room.removeEntity client.entity

            room.removeClient client

    if not (Object.keys room.clients).length
        Game.Room.remove room


###
When a client sends input to a room,
perform different actions depending on the type
of input.
###
Game.onRoomInput = (clientData, roomName, type, parameters) ->
    room = Game.Room.find roomName

    if room
        client = room.findClient clientData.id

        if client
            if type == 'setDirection'
                client.entity.direction = parameters.direction


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
