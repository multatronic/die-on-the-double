angular
    .module 'rooms'
    .config [
        '$stateProvider'
        ($stateProvider) ->
            $stateProvider
                .state 'rooms',
                    url: '/rooms'
                    templateUrl: 'client/rooms/views/rooms.tpl.html'
                    controller: 'RoomCtrl'
                    controllerAs: 'rooms'
                .state 'rooms.show',
                    url: '/:id'
                    templateUrl: 'client/rooms/views/rooms.show.tpl.html'
                    controller: 'RoomCtrl'
                    controllerAs: 'rooms'
                .state 'room_controller',
                    url: '/controllers/:id'
                    templateUrl: 'client/rooms/views/room_controller.tpl.html'
                    controller: 'RoomControllerCtrl'
                    controllerAs: 'ctrl'
    ]
