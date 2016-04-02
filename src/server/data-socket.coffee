###
Data exchange logic. Deals with notifications, exchanging player info, etc.
Also deals with triggering new events.
###

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

        socket._clientData.room = room

        Streamy
            .rooms room
            .emit '__join__',
                sid: Streamy.id socket
                room: room
                client: socket._clientData

        # If joining a new room, leave all other rooms
        for otherRoom in Streamy.Rooms.allForSession(Streamy.id(socket)).fetch()
            if otherRoom.name != room
                Streamy.leave otherRoom.name, socket

        # Game join handler
        Game.onRoomJoin socket._clientData, room

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
                client: socket._clientData

        # Game leave handler
        Game.onRoomLeave socket._clientData, room

Streamy
    .on 'clientData', (data, socket) ->
        console.log "Client: Client '#{Streamy.id(socket)}' identified as client '#{data.name}' of type '#{data.type}'"
        socket._clientData = data
        socket._clientData.id = Streamy.id socket

        # Notify all rooms this client is in about the updated client data
        for room in Streamy.Rooms.allForSession(Streamy.id(socket)).fetch()
            Streamy
                .rooms room
                .emit 'clientData',
                    sid: Streamy.id socket
                    client: socket._clientData

Streamy
    .on 'clientInput', (data, socket) ->
        console.log "Client: Client '#{Streamy.id(socket)}' sent input of type '#{data.type}'"

        # Game input handler
        Game.onRoomInput socket._clientData, socket._clientData.room, data.type, data.parameters
