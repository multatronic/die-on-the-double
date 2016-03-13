angular
    .module Meteor.settings.public.applicationModule, [
        'ngAnimate'
        'ngAria'
        'ngMaterial'
        'angular-meteor'
        'angular.filter'
        'ui.router'
        'angularMoment'
        'home'
        'rooms'
        'socket'
    ]
    .config [
        '$urlRouterProvider'
        '$locationProvider'
        '$stateProvider'
        ($urlRouterProvider, $locationProvider, $stateProvider) ->
            # bla
    ]
    .run [
        '$rootScope'
        ($rootScope) ->
            $rootScope.applicationName = Meteor.settings.public.applicationName
    ]

onReady = () ->
    angular
        .bootstrap document, [Meteor.settings.public.applicationModule],
            strictDi: true

if Meteor.isCordova
  angular.element document
    .on 'deviceready', onReady
else
  angular.element document
    .ready onReady
