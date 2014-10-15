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
    qStatsEngine.run(
      startDate: $scope.filter.startDate
      endDate: $scope.filter.endDate
    ).then (data) ->
      $scope.teams = data
  $scope.teams = []
  _runEngine()

  $scope.filterp = (value) ->
    gameFilter = value.games >= $scope.filter.games
    regionFilter = $scope.filter.region == "all" || value.region == $scope.filter.region
    nameFilter = value.name.toLowerCase().indexOf($scope.filter.name.toLowerCase()) >= 0
    
    gameFilter && regionFilter && nameFilter

  $scope.$watch "filter.startDate", (newValue) ->
    if moment(newValue).isValid()
      _runEngine()

  $scope.$watch "filter.endDate", (newValue) ->
    if moment(newValue).isValid()
      _runEngine()
