angular
    .module 'socket'
    .factory 'DataSocket', [
        '$log'
        '$timeout'
        ($log, $timeout) ->
            $log.debug 'Initializing DataSocket'
            DataSocketBase = {}

            DataSocketBase.joinRoom = (roomName, playerName = null, clientType = 'controller') ->
                playerData =
                    name: playerName
                    type: clientType

                $timeout () ->
                    $log.debug 'Sending player data to server', playerData
                    Streamy
                        .emit 'playerData', playerData

                    $log.debug "Joining room '#{roomName}'"
                    Streamy
                        .join roomName
                , 2000

            DataSocketBase
    ]
