angular
    .module 'rooms'
    .config [
        '$stateProvider'
        ($stateProvider) ->
            $stateProvider
                .state 'rooms',
                    url: '/rooms'
                    templateUrl: 'client/rooms/views/rooms.tpl.html'
                    controller: 'RoomListCtrl'
                    controllerAs: 'roomListCtrl'
                .state 'room_display',
                    url: '/rooms/:id'
                    templateUrl: 'client/rooms/views/room_show.tpl.html'
                    controller: 'RoomCtrl'
                    controllerAs: 'ctrl'
                .state 'room_controller',
                    url: '/controllers/:id'
                    templateUrl: 'client/rooms/views/room_controller.tpl.html'
                    controller: 'RoomControllerCtrl'
                    controllerAs: 'ctrl'
    ]
