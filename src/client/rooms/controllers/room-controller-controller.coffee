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

            $scope.sendPlayerInfo = () =>
                DataSocket
                    .sendPlayerInfo $scope.playerName, clientType = clientType

            $scope.joinRoom = () ->
                DataSocket
                    .joinRoom roomId, $scope.playerName, clientType = clientType

            $scope.setPlayerVector = (vector) ->
                DataSocket
                    .emit 'setPlayerVector', vector

            $scope.joinRoom()
    ]
