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


class Game.RoomState

    ###
    Room states. Each room is started as "STOPPED",
    turns "ACTIVE" once the round begins and can
    be "PAUSED".
    ###

    @STOPPED = 0
    @PAUSED = 1
    @ACTIVE = 2


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
    state: Game.RoomState.STOPPED

    ###
    Current players.

    Only modify with `addPlayer` and `removePlayer` to avoid breakage.
    ###
    players: {}

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


class Game.Player

    ###
    Game player. Has an ID, a name, a score and a color.
    ###

    ###
    ID.
    ###
    id: null,

    ###
    Name.
    ###
    name: null,

    ###
    Constructor.
    ###
    constructor: (@id, @name) ->
        console.log "Creating player '#{@name}' with ID '#{@id}'"


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
