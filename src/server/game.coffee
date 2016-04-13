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


# ###
# Game helpers.
# ###
Game.helpers =
    ###
    Helper function for generating a random integer from a range.
    ###
    randomIntBetween: (min, max) ->
        Math.floor (Math.random() * (max - min + 1) + min)


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
    state: null

    ###
    {@inheritDoc}
    ###
    constructor: () ->
        super

        @state = Game.State.STOPPED

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
    size: null

    ###
    World, or whatever you want to call it. A 3D point container with
    information regarding which entity occupies what coordinate
    in 3D space.
    ###
    world: null

    ###
    {@inheritDoc}
    ###
    constructor: (@size = [12, 12, 6]) ->
        super

        @world = {}

        # Initialize world
        for x in [0 .. (@size[0] - 1)]
            @world[x] = {}

            for y in [0 .. (@size[1] - 1)]
                @world[x][y] = {}

                for z in [0 .. (@size[2] - 1)]
                    @world[x][y][z] = null

    ###
    Get a random (unoccupied) coordinate in this level.
    ###
    getRandomCoordinate: () ->
        # @TODO Make the random coordinate not so random
        # and ensure the returned coordinate is not actually being occupied
            [
                Game.helpers.randomIntBetween 0, (@size[0] - 1)
                Game.helpers.randomIntBetween 0, (@size[1] - 1)
                Game.helpers.randomIntBetween 0, (@size[2] - 1)
            ]

    ###
    Get state as a plain object.
    ###
    getAsObject: () ->
            id: @id
            size: @size


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
    state: null

    ###
    Current clients.

    Only modify with `addClient` and `removeClient` to avoid breakage.
    ###
    clients: null

    ###
    Current entities.

    Only modify with `addEntity` and `removeEntity` to avoid breakage.
    ###
    entities: null

    ###
    The current room level.
    ###
    level: null

    ###
    The primary difficulty setting.

    Only modify with `setDifficulty` to avoid breakage.
    ###
    difficulty: null

    ###
    Constructor.
    ###
    constructor: (@id, @name) ->
        super

        @level = new Game.Level [12, 12, 6]
        @entities = {}
        @clients = {}
        @difficulty = 1
        @state = Game.State.ACTIVE
        @spawnApple()

    ###
    Spawn an apply in the level attached to this room.
    ###
    spawnApple: () ->
        entity = new Game.AppleEntity
        entity.position = @level.getRandomCoordinate()
        @level.world[entity.position[0]][entity.position[1]][entity.position[2]] = entity
        @addEntity entity

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

    ###
    Get state as a plain object.
    ###
    getAsObject: () ->
            id: @id
            name: @name
            difficulty: @difficulty
            level: @level.getAsObject()
            entities: (v.getAsObject() for k, v of @entities)
            state: @state


class Game.Client extends Game.Loggable

    ###
    Game client. Wrapper around a communication channel
    such as a socket, but explicitly linked to a specific
    room. Can optionally be linked to a game entity,
    signifying a player participating in the game.
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
    Socket.

    @type mixed
    ###
    socket: null

    ###
    {@inheritDoc}
    ###
    constructor: (@id, @name, @type, @socket) ->
        super

    ###
    Have an event handled by this client.
    ###
    handle: (event) ->
        Streamy.emit event.constructor.type, event, @socket


class Game.Entity extends Game.Loggable

    ###
    Game entity. Can be rendered on the map.
    ###

    ###
    Positional coordinates.

    @type array<integer, integer, integer>
    ###
    position: null

    ###
    Positional history.

    @type array<array<integer, integer, integer>>
    ###
    positionHistory: null

    ###
    Directional vector.

    @type array<integer, integer, integer>
    ###
    direction: null

    ###
    {@inheritDoc}
    ###
    constructor: () ->
        super

        @position = [0, 0, 0]
        @positionHistory = []
        @direction = [0, 0, 0]

    ###
    Get state as a plain object.
    ###
    getAsObject: () ->
            id: @id
            position: @position
            positionHistory: @positionHistory
            direction: @direction


class Game.SnakeEntity extends Game.Entity

    ###
    Snake entity. The position is used as the
    snake's front. Everything else is part of the position history.
    ###


class Game.AppleEntity extends Game.Entity

    ###
    Apple entity.
    ###


class Game.EventManager extends Game.StartStoppable

    ###
    Game event manager. In charge of running the main
    event loop, triggering periodic ticks and the like.
    ###

    ###
    Event queue.
    ###
    events: null

    ###
    Event handlers.
    ###
    handlers: null

    ###
    {@inheritDoc}
    ###
    constructor: () ->
        super

        @events = []
        @handlers = {}

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
        for id, room of Game.rooms when room.state == Game.State.ACTIVE
            room.tickCounter ?= 0
            room.tickCounter += 1

            if room.tickCounter >= (Game.constants.ticksPerSecond / room.difficulty)
                room.tickCounter = 0
                @onRoomTick event, room

    ###
    Handle a room tick.
    ###
    onRoomTick: (event, room) ->
        # Calculate latest positions for all entities
        for id, entity of room.entities
            # No need to perform calculations for stuff which isn't moving
            # @TODO Determine whether performance would be increased if we use array sum != 0 instead
            if (entity.direction.indexOf 1) == -1 && (entity.direction.indexOf -1) == -1
                continue

            oldPosition = entity.position[..]
            position = entity.position
            direction = entity.direction
            moveOk = true

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
            oldestPosition = entity.positionHistory.pop()

            # If there is already an entity at the entity's latest position,
            # we have a collision on our hands
            target = room.level.world[position[0]][position[1]][position[2]]
            if target
                # A collision with an apple entity means we gain a "point",
                # whereas anything else means we've lost
                if target.constructor.name == Game.AppleEntity.name
                    # Replace apple
                    room.removeEntity target
                    room.spawnApple()

                    # Increase the size of our player
                    entity.positionHistory.push oldestPosition
                    oldestPosition = null
                else
                    # @TODO Lose a life here, or lose the game
                    # Fail movement
                    moveOk = false

            if moveOk
                # Place the entity at its newest position
                room.level.world[position[0]][position[1]][position[2]] = entity

                # Remove the entity from its oldest position if required
                if oldestPosition
                    room.level.world[oldestPosition[0]][oldestPosition[1]][oldestPosition[2]] = null

        # Generate status update
        status = room.getAsObject()
        status['constructor'].type = 'statusUpdate'

        # Dispatch status update to all attached
        # attached clients of type 'DISPLAY'
        for id, client of room.clients when client.type == Game.ClientType.DISPLAY
            client.handle status


###
When a client joins a room,
create a room object if it doesn't yet exist.
Create a new client object and add it to the room
as well. In the case of a player joining,
create a new entity and link it to the client.
###
Game.onRoomJoin = (clientData, roomName, socket) ->
    room = Game.Room.find roomName

    if not room
        room = new Game.Room roomName, roomName
        Game.rooms[room.id] = room

    client = room.findClient clientData.id

    if not client
        client = new Game.Client clientData.id, clientData.name, clientData.type, socket

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
Game.onRoomLeave = (clientData, roomName, socket) ->
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
            else if type == 'setState'
                room.setState Game.State[parameters.state]


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
