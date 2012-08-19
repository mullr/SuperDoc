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


  $scope.selectPackage = (pkg) ->
    $scope.selectedPackage = pkg
    if(pkg.docs.length > 0)
      $scope.selectDoc(pkg.docs[0])
    else
      $scope.selectDoc(null)
    
  $scope.selectDoc = (doc) ->
    $scope.selectedDoc = doc


superDoc.filter 'prettifyHomepageUrl', () ->
  (url) ->
    match = /http:\/\/github.com\/(.*)/.exec(url)
    if match
      return "github/#{match[1]}"
    else
      return url
