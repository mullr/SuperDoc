superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

window.SuperDocController = ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()

  $scope.selectedPackage = null
  $scope.selectedDoc = null

  $scope.selectPackage = (pkg) ->
    $scope.selectedPackage = pkg

    if(pkg.docs.length > 0)
      $scope.selectDoc(pkg.docs[0])
    else
      $scope.selectDoc(null)

   
  $scope.selectDoc = (doc) ->
    $scope.selectedDoc = doc


  $scope.tabs = [
    name: "Documentation"
    template: "documentation.html"
  ,
    name: "Package info"
    template: "packageInfo.html"
  ,
    name: "Files"
    template: "files.html"
  ]

  $scope.selectedTab = $scope.tabs[0]
  $scope.selectTab = (tab) -> $scope.selectedTab = tab

class FileNode
  constructor: (@name) ->
    @children = {}
    @selected = false

  displayName: ->
    if @isDirectory()
      @name + "/"
    else
      @name

  selectChild: (childNode) ->
    v.selected = false for own k,v of @children
    childNode?.selected = true


  # Add a child node like mkdir -p
  addChild: (childPath) ->
    return if childPath is ""

    pathSegments = childPath.split('/')
    return if pathSegments.length is 0

    nextPathSegment = pathSegments[0]
    if not @children[nextPathSegment]?
      @children[nextPathSegment] = new FileNode(nextPathSegment)

    # remove the first path segment and recurse
    pathSegments.shift()
    @children[nextPathSegment].addChild pathSegments.join('/')

  isDirectory: ->
    # It's a directory if the children object has any properties at all
    for own k,v of @children
      return true
    return false

  isFile: -> not (@isDirectory())


createTreeFromListOfPaths = (paths) ->
  root = new FileNode("")
  root.addChild p for p in paths
  return root


window.FileSelectorController = ($scope) ->
  root = createTreeFromListOfPaths($scope.selectedPackage.files)
  root.selected = true

  $scope.panes = [root]
  $scope.selectedFileUrl

  indexOfPaneWhichContains = (node) ->
    for pane, paneIndex in $scope.panes
      for own k,v of pane.children
        return [pane,paneIndex] if v is node
    return null

  $scope.selectNode = (clickedNode) ->
    [lastPaneToKeep, indexOfLastPaneToKeep] = indexOfPaneWhichContains(clickedNode)

    panesWhichWillGoAway = $scope.panes.slice(indexOfLastPaneToKeep + 1, $scope.panes.length)
    p.selectChild(null) for p in panesWhichWillGoAway

    lastPaneToKeep.selectChild(clickedNode)

    newPanes = $scope.panes.slice(0, indexOfLastPaneToKeep + 1)
    newPanes.push clickedNode if clickedNode.isDirectory()
    $scope.panes = newPanes

    if clickedNode.isFile()
      selectionPath = (p.name for p in $scope.panes).join('/')
      selectionPath += '/' + clickedNode.name
      $scope.selectedFileUrl = $scope.selectedPackage.fileBaseUrl + selectionPath
    else
      $scope.selectedFileUrl = null



