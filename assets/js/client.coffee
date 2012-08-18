superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

window.SuperDocController = ($scope, $resource, $http) ->
  $scope.moduleList = $resource('/modules').get()
  $scope.selectedModuleDocumentationUrl = ""

  $scope.activeTabName = "Readme"
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


superDoc.filter 'prettifyHomepageUrl', () ->
  (url) ->
    match = /http:\/\/github.com\/(.*)/.exec(url)
    if match
      return "github/#{match[1]}"
    else
      return url
