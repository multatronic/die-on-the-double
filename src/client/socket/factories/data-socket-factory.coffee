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
                    socketConnect: 'data_socket.events.socket_connect'
                    socketDisconnect: 'data_socket.events.socket_disconnect'
                    statusUpdateReceive: 'data_socket.events.status_update'

            DataSocketBase.sendClientInput = (type, parameters = []) ->
                clientInput =
                    type: type
                    parameters: parameters

                $log.debug 'DataSocket: Sending client input to server', clientInput
                Streamy
                    .emit 'clientInput', clientInput

            DataSocketBase.sendClientInfo = (name = null, clientType = 'player') ->
                clientData =
                    name: name
                    type: clientType

                $log.debug 'DataSocket: Sending client data to server', clientData
                Streamy
                    .emit 'clientData', clientData

            DataSocketBase.joinRoom = (roomName) ->
                $log.debug "DataSocket: Joining room '#{roomName}'"
                Streamy
                    .join roomName

            # Handler for status updates
            Streamy
                .on 'statusUpdate', (data, socket) ->
                    $log.debug "DataSocket: Received 'statusUpdate' data", data
                    event = DataSocketBase.options.events.statusUpdateReceive

                    $log.debug "DataSocket: Triggering event '#{event}'"
                    $rootScope.$emit event,
                        data
                        socket

            # Handler for joins
            Streamy
                .on '__join__', (data, socket) ->
                    $log.debug "DataSocket: Received '__join__' data", data
                    event = null

                    if data.client.type == 'player'
                        event = DataSocketBase.options.events.roomPlayerJoin
                    else
                        event = DataSocketBase.options.events.roomDisplayConnect

                    $log.debug "DataSocket: Triggering event '#{event}'"
                    $rootScope.$emit event,
                        data
                        socket

            # Handler for leaves
            Streamy
                .on '__leave__', (data, socket) ->
                    $log.debug "DataSocket: Received '__leave__' data", data
                    event = null

                    if data.client.type == 'player'
                        event = DataSocketBase.options.events.roomPlayerLeave
                    else
                        event = DataSocketBase.options.events.roomDisplayDisconnect

                    $log.debug "DataSocket: Triggering event '#{event}'"
                    $rootScope.$emit event,
                        data
                        socket

            DataSocketBase
    ]
