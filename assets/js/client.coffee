superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

window.SuperDocController = ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()
  $scope.selectedPackageDocumentationUrl = ""

  $scope.activeTabName = "Readme"
  $scope.selectedPackage = null

  $scope.htmlData = null
  $scope.textData = null

  $scope.selectPackage = (pak) ->
    $scope.selectedPackage = pak

    console.log pak
    $http.get(pak.url).success (data, status, headers, config) ->
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
