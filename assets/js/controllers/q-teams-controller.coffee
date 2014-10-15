qdata.controller "qTeamsController", ($scope,$filter,qStatsEngine,qExporter,qAlerter) ->
  $scope.filter =
    games: 1
    region: "all"
    name: ""
    startDate: moment("2014-09-01").toDate()
    endDate: moment().toDate()

  $scope.sort =
    field: "wins"
    desc: true

  _runEngine = ->
    $scope.teams = qStatsEngine.run
      startDate: $scope.filter.startDate
      endDate: $scope.filter.endDate
  _runEngine()

  $scope.filterp = (value) ->
    gameFilter = value.games >= $scope.filter.games
    regionFilter = $scope.filter.region == "all" || value.region == $scope.filter.region
    nameFilter = value.name.toLowerCase().indexOf($scope.filter.name.toLowerCase()) >= 0
    
    gameFilter && regionFilter && nameFilter

  $scope.exporting = false

  $scope.exportGoogle = ->
    $scope.exporting = true
    toExport = $filter("filter")($scope.teams,$scope.filterp)
    toExport = $filter("orderBy")(toExport,$scope.sort.field,$scope.sort.desc)
    qExporter.google(toExport).then((data) ->
      qAlerter.success
        title: "Export completed!"
        body: "Successfully exported Google Doc: \"" + data.title + "\""
    ).catch(->
      qAlerter.error
        title: "Export failed!"
        body: "Error exporting to Google Doc"
    ).finally ->
      $scope.exporting = false

  $scope.$watch "filter.startDate", (newValue) ->
    if moment(newValue).isValid()
      _runEngine()

  $scope.$watch "filter.endDate", (newValue) ->
    if moment(newValue).isValid()
      _runEngine()
