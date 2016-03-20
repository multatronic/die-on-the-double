# Deal with socket data coming from displays or controllers
Streamy
    .onConnect (socket) ->
        console.log "Socket: Client '#{Streamy.id(socket)}' connected"

        return true

Streamy
    .onDisconnect (socket) ->
        console.log "Socket: Client '#{Streamy.id(socket)}' disconnected"

        return true

originalStreamyOnJoin = Streamy.Rooms.onJoin
Streamy
    .Rooms
    .onJoin = (room, socket) ->
        console.log "Rooms: Client '#{Streamy.id(socket)}' joined room '#{room}'"

        # # Call original callback
        # originalStreamyOnJoin room, socket

        Streamy
            .rooms room
            .emit '__join__',
                sid: Streamy.id socket
                room: room
                player: socket._playerData

        # If joining a new room, leave all other rooms
        for otherRoom in Streamy.Rooms.allForSession(Streamy.id(socket)).fetch()
            if otherRoom.name != room
                Streamy.leave otherRoom.name, socket

originalStreamyOnLeave = Streamy.Rooms.onLeave
Streamy
    .Rooms
    .onLeave = (room, socket) ->
        console.log "Rooms: Client '#{Streamy.id(socket)}' left room '#{room}'"

        # # Call original callback
        # originalStreamyOnLeave room, socket

        Streamy
            .rooms room
            .emit '__leave__',
                sid: Streamy.id socket
                room: room
                player: socket._playerData

Streamy
    .on 'playerData', (data, socket) ->
        console.log "Player: Client '#{Streamy.id(socket)}' identified as player '#{data.name}' of type '#{data.type}'"
        socket._playerData = data

        # Notify all rooms this player is in about the updated player data
        for room in Streamy.Rooms.allForSession(Streamy.id(socket)).fetch()
            Streamy
                .rooms room
                .emit 'playerData',
                    sid: Streamy.id socket
                    player: socket._playerData
