superDoc = angular.module 'SuperDoc', ['ngResource', 'bootstrap']

superDoc.controller "SuperDocController", ($scope, $resource, $http) ->
  $scope.project = $resource('/project').get()
  $scope.selectedContentUrl = null

  $scope.$on 'showContent', (e,url) -> $scope.selectedContentUrl = url


superDoc.controller "PanelListViewController", ($scope, $controller) ->
  $scope.panels = [ {template: 'packageListPanel.html', options:{}} ]
  $scope.selectedPackage = null

  findPanel = (panel) -> for p,i in $scope.panels
    return i if panel is p

  # maintain the selected package here so all panes can have access to it
  $scope.$on 'selectedPackageChanged', (e,pkg) ->
    $scope.selectedPackage = pkg

  $scope.$on 'showPanel', (e, panelOptions) ->
    {parentPanel, template} = panelOptions

    indexOfLastPanelToKeep = findPanel(parentPanel)
    $scope.panels = $scope.panels.slice(0, indexOfLastPanelToKeep + 1)

    # be sure to pass through most stuff, so the panel itself can get custom options
    delete $scope.panels.parentPanel
    $scope.panels.push panelOptions


superDoc.controller "PackageListController", ($scope) ->
  $scope.selectPackage = (pkg) ->
    $scope.$emit 'selectedPackageChanged', pkg
    $scope.$emit 'showPanel',
      parentPanel: $scope.panel
      template:    'directoryPanel.html'
      node:        createTreeFromListOfPaths(pkg.files)


superDoc.controller "DirectoryPanelController", ($scope) ->
  $scope.node         = $scope.panel.node
  $scope.selectedChild = null

  $scope.selectNode   = (child) ->
    $scope.selectedChild = child
    if child.isDirectory()
      $scope.$emit 'showContent', null
      $scope.$emit 'showPanel',
        parentPanel: $scope.panel
        template:    'directoryPanel.html'
        node:        child
    else
      contentUrl = $scope.selectedPackage.fileBaseUrl + child.pathFromRoot().join('/')
      $scope.$emit 'showContent', contentUrl
      $scope.$emit 'showPanel',
        parentPanel: $scope.panel
        template:    null



class FileNode
  constructor: (@name, @parent) ->
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

  pathFromRoot: ->
    return [] if @isRoot()
    return @parent.pathFromRoot().concat [@name]

createTreeFromListOfPaths = (paths) ->
  root = new FileNode("")
  root.addChild p for p in paths
  return root


window.FileSelectorController = ($scope) ->
  root = createTreeFromListOfPaths($scope.selectedPackage.files)
  root.selected = true

  $scope.panes = [root]

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
      $scope.parent.selectedContentUrl = $scope.selectedPackage.fileBaseUrl + selectionPath
    else
      $scope.parent.selectedContentUrl = null

