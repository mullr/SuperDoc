superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

contentViewers = [
  pattern: /text\/plain/
  template: "plainTextViewer.html"
,
  pattern: /text\/html/
  template: "htmlViewer.html"
,
  pattern: /.*/
  template: "plainTextViewer.html"
]


superDoc.controller "SuperDocController", ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()
  $scope.content = null
  $scope.contentViewer = null
  $scope.selectedNode = null
  $scope.pathToSelectedNode = []
  $scope.selectedFileNode = null


  useContentAt = (url) ->
    if not url?
      $scope.content = null
      return

    req = $http.get(url)
    req.success (data, status, headers, config) ->
      contentType = headers("Content-Type")
      for viewer in contentViewers
        if contentType.match(viewer.pattern)
          $scope.contentViewer = viewer.template
          break

      $scope.content = data


  $scope.$on 'selectPackage', (e,pkg) ->
    $scope.selectedPackage = pkg
    $scope.selectedNode = createTreeFromListOfPaths(pkg.files)
    $scope.pathToSelectedNode = []
    $scope.selectedContentUrl = null
    $scope.selectedFileNode = null

  $scope.$on 'selectNode', (e,clickedNode) ->
    if clickedNode.isDirectory()
      useContentAt(null)
      $scope.pathToSelectedNode.push $scope.selectedNode if $scope.selectedNode?
      $scope.selectedNode = clickedNode
      $scope.selectedFileNode = null
    else
      pathArray = $scope.pathToSelectedNode.concat [$scope.selectedNode, clickedNode]
      path = (n.name for n in pathArray).join('/')
      useContentAt($scope.selectedPackage.fileBaseUrl + path)
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


