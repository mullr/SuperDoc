superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

superDoc.controller "SuperDocController", ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()
  $scope.selectedContentUrl = null
  $scope.selectedNode = null
  $scope.pathToSelectedNode = []
  $scope.selectedFileNode = null

  $scope.$on 'selectPackage', (e,pkg) ->
    $scope.selectedPackage = pkg
    $scope.selectedNode = createTreeFromListOfPaths(pkg.files)
    $scope.pathToSelectedNode = []
    $scope.selectedContentUrl = null
    $scope.selectedFileNode = null

  $scope.$on 'selectNode', (e,clickedNode) ->
    if clickedNode.isDirectory()
      $scope.selectedContentUrl = null
      $scope.pathToSelectedNode.push $scope.selectedNode if $scope.selectedNode?
      $scope.selectedNode = clickedNode
      $scope.selectedFileNode = null
    else
      pathArray = $scope.pathToSelectedNode.concat [$scope.selectedNode, clickedNode]
      path = (n.name for n in pathArray).join('/')
      contentUrl = $scope.selectedPackage.fileBaseUrl + path
      $scope.selectedContentUrl = contentUrl
      $scope.selectedFileNode = clickedNode

  $scope.$on 'goBackToNode', (e,node) ->
    path = $scope.pathToSelectedNode
    $scope.pathToSelectedNode = path.slice(0, path.indexOf(node))
    $scope.selectedNode = node

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
      @children[nextPathSegment] = new FileNode(nextPathSegment, this)

    # remove the first path segment and recurse
    pathSegments.shift()
    @children[nextPathSegment].addChild pathSegments.join('/')

  isDirectory: ->
    # It's a directory if the children object has any properties at all
    for own k,v of @children
      return true
    return false

  isFile: -> not (@isDirectory())

  isRoot: -> @name is ""

  breadcrumbName: ->
    return "_" if @isRoot()
    return @name

createTreeFromListOfPaths = (paths) ->
  root = new FileNode("")
  root.addChild p for p in paths
  return root


