angular
    .module 'rooms'
    .controller 'RoomListCtrl', [
        'RoomFactory'
        '$scope'
        (RoomFactory, $scope) ->
            # get room list cursor and wrap it as an array
            $scope.helpers
                rooms: () ->
                    RoomFactory.getRoomList()
            return
    ]
