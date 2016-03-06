angular
    .module 'home'
    .controller 'HomeCtrl', [
        '$scope'
        '$mdSidenav'
        '$state'
        '$rootScope'
        ($scope, $mdSidenav, $state, $rootScope) ->
            @ctrlName = 'HomeCtrl'
            $scope.applicationName = $rootScope.applicationName

            $scope.toggleSidenav = (target) ->
                $mdSidenav(target).toggle()

            $scope.goto = (state, stateParams = {}) ->
                $state.go state, stateParams

            $scope.navigationItems = [
                    state: 'home',
                    icon: 'home',
                    label: 'Home'
                ,
            ]
    ]
