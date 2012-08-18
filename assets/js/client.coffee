angular.module 'SuperDoc', ['ngResource']

window.SuperDocController = ($scope, $resource, $http) ->
  $scope.moduleList = $resource('/modules').get()
  $scope.selectedModuleDocumentationUrl = ""

  $scope.selectedModule = null
  $scope.htmlData = null
  $scope.textData = null

  $scope.selectModule = (module) ->
    $scope.selectedModule = module
    $http.get(module.url).success (data, status, headers, config) ->
      contentType = headers('Content-Type')
      if contentType.indexOf('text/html') isnt -1
        $scope.htmlData = data
        $scope.textData = null
      else
        $scope.htmlData = null
        $scope.textData = data




