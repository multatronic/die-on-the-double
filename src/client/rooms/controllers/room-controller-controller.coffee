angular
    .module 'rooms'
    .controller 'RoomControllerCtrl', [
        '$scope'
        '$stateParams'
        '$log'
        '$timeout'
        'DataSocket'
        ($scope, $stateParams, $log, $timeout, DataSocket) ->
            roomId = $stateParams.id
            clientType = 'player'
            $scope.playerName = 'Nameless One'

            $scope.initController = () =>
                DataSocket
                    .sendClientInfo $scope.playerName, clientType = clientType

                DataSocket
                    .joinRoom roomId

            $scope.setPlayerDirection = (direction) ->
                DataSocket
                    .sendClientInput 'setDirection',
                        direction: direction

            $timeout $scope.initController, 250
    ]
