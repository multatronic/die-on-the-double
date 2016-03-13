angular
    .module 'rooms'
    .controller 'RoomCtrl', [
        '$scope'
        '$stateParams'
        '$log'
        'DataSocket'
        ($scope, $stateParams, $log, DataSocket) ->
            roomId = $stateParams.id
            clientType = 'display'

            DataSocket
                .joinRoom roomId, 'DISPLAY', clientType = clientType
    ]
