angular
    .module 'rooms'
    .config [
        '$stateProvider'
        ($stateProvider) ->
            $stateProvider
                .state 'rooms',
                    url: '/rooms'
                    templateUrl: 'client/rooms/views/rooms.tpl.html'
                    controller: 'RoomsCtrl'
                    controllerAs: 'rooms'
                .state 'rooms.show',
                    url: '/:id'
                    templateUrl: 'client/rooms/views/rooms.show.tpl.html'
                    controller: 'RoomCtrl'
                    controllerAs: 'room'
                .state 'rooms.controllers',
                    url: '/:id/controllers'
                    templateUrl: 'client/rooms/views/rooms.controllers.tpl.html'
                    controller: 'RoomControllerCtrl'
                    controllerAs: 'roomController'
    ]
