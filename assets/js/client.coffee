superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

window.SuperDocController = ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()
  $scope.selectedPackageDocumentationUrl = ""

  $scope.selectedPackage = null

  $scope.tabs = [
    name: "Documentation"
    template: "documentation.html"
  ,
    name: "Package info"
    template: "packageInfo.html"
  ]

  $scope.selectedTab = $scope.tabs[0]
  $scope.selectTab = (tab) -> $scope.selectedTab = tab


  $scope.selectedDoc = null
  $scope.selectedDocHtmlData = null
  $scope.selectedDocTextData = null

  showText = (data) ->
    $scope.selectedDocHtmlData = null
    $scope.selectedDocTextData = data

  showHtml = (data) ->
    $scope.selectedDocHtmlData = data
    $scope.selectedDocTextData = null

  $scope.selectPackage = (pkg) ->
    $scope.selectedPackage = pkg
    if(pkg.docs.length > 0)
      $scope.selectDoc(pkg.docs[0])
    else
      showText "No documentation found"
    
  $scope.selectDoc = (doc) ->
    $scope.selectedDoc = doc
    $http.get(doc.url).success (data, status, headers, config) ->
      contentType = headers('Content-Type')
      if contentType.indexOf('text/html') isnt -1
        showHtml(data)
      else
        showText(data)


superDoc.filter 'prettifyHomepageUrl', () ->
  (url) ->
    match = /http:\/\/github.com\/(.*)/.exec(url)
    if match
      return "github/#{match[1]}"
    else
      return url
