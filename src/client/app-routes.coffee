angular
    .module Meteor.settings.public.applicationModule
    .config [
        '$urlRouterProvider'
        '$locationProvider'
        '$stateProvider'
        ($urlRouterProvider, $locationProvider, $stateProvider) ->
            $urlRouterProvider
                .otherwise '/home'

            $locationProvider
                .html5Mode false
    ]
