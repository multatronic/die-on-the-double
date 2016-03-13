angular
    .module 'rooms'
    .controller 'RoomControllerCtrl', [
        '$scope'
        '$stateParams'
        '$log'
        'DataSocket'
        ($scope, $stateParams, $log, DataSocket) ->
            roomId = $stateParams.id
            clientType = 'controller'
            $scope.playerName = 'Nameless One'

            $scope.joinRoom = () ->
                DataSocket
                    .joinRoom roomId, $scope.playerName, clientType = clientType

            # Handler for join toasts
            Streamy
                .on '__join__', (data, socket) ->
                    $log.debug data, socket

            # Handler for leave toasts
            Streamy
                .on '__leave__', (data, socket) ->
                    $log.debug data, socket
    ]
