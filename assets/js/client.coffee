angular.module 'SuperDoc', ['ngResource']

class window.SuperDocController
  constructor: ($scope, $resource) ->
    $scope.moduleList = $resource('/modules').get()

