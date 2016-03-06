angular
    .module 'home'
    .config [
        '$stateProvider'
        ($stateProvider) ->
            $stateProvider
                .state 'home',
                    url: '/home'
                    templateUrl: 'client/home/views/home.tpl.html'
                    controller: 'HomeCtrl'
                    controllerAs: 'home'
    ]
