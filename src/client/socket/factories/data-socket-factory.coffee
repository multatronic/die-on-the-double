angular
    .module 'socket'
    .factory 'DataSocket', [
        '$log'
        '$rootScope'
        '$timeout'
        ($log, $rootScope, $timeout) ->
            $log.debug 'DataSocket: Initializing'
            DataSocketBase = {}

            DataSocketBase.options =
                events:
                    roomPlayerJoin: 'data_socket.events.rooms.player_join'
                    roomPlayerLeave: 'data_socket.events.rooms.player_leave'
                    roomDisplayConnect: 'data_socket.events.rooms.display_connect'
                    roomDisplayDisconnect: 'data_socket.events.rooms.display_disconnect'
                    playerDataReceive: 'data_socket.events.player_data_receive'
                    socketConnect: 'data_socket.events.socket_connect'
                    socketDisconnect: 'data_socket.events.socket_disconnect'

            DataSocketBase.sendPlayerInfo = (playerName = null, clientType = 'controller') ->
                playerData =
                    name: playerName
                    type: clientType

                $log.debug 'DataSocket: Sending player data to server', playerData
                Streamy
                    .emit 'playerData', playerData

            DataSocketBase.joinRoom = (roomName, playerName = null, clientType = 'controller') ->
                $timeout () =>
                    @sendPlayerInfo playerName, clientType

                    $log.debug "DataSocket: Joining room '#{roomName}'"
                    Streamy
                        .join roomName
                , 2000

                # Handler for player data
                Streamy
                    .on 'playerData', (data, socket) =>
                        $log.debug "DataSocket: Received 'playerData' data", data
                        event = @options.events.playerDataReceive

                        $log.debug "DataSocket: Triggering event '#{event}'"
                        $rootScope.$emit event,
                            data
                            socket

                # Handler for joins
                Streamy
                    .on '__join__', (data, socket) =>
                        $log.debug "DataSocket: Received '__join__' data", data
                        event = null

                        if data.player.type == 'controller'
                            event = @options.events.roomPlayerJoin
                        else
                            event = @options.events.roomDisplayConnect

                        $log.debug "DataSocket: Triggering event '#{event}'"
                        $rootScope.$emit event,
                            data
                            socket

                # Handler for leaves
                Streamy
                    .on '__leave__', (data, socket) =>
                        $log.debug "DataSocket: Received '__leave__' data", data
                        event = null

                        if data.player.type == 'controller'
                            event = @options.events.roomPlayerLeave
                        else
                            event = @options.events.roomDisplayDisconnect

                        $log.debug "DataSocket: Triggering event '#{event}'"
                        $rootScope.$emit event,
                            data
                            socket

            DataSocketBase
    ]
