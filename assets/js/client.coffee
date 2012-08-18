angular.module 'SuperDoc', ['ngResource']

window.SuperDocController = ($scope, $resource) ->
  $scope.moduleList = $resource('/modules').get()
  $scope.selectedModuleDocumentationUrl = ""

  $scope.selectedModule = null

  $scope.selectModule = (module) ->
    $scope.selectedModule = module
    $scope.selectedModuleDocumentationUrl = module.url



