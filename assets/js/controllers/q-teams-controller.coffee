qdata.controller "qTeamsController", ($scope,$filter,qStatsEngine,qExporter,qAlerter) ->
  $scope.columns =
    text:
      buttonDefaultText: "Columns"
    icons:
      ok: "fa fa-check"
      remove: "fa fa-remove"
      button: "fa fa-columns"
    settings:
      dynamicTitle: false
    data: [
      {
        id: "name"
        label: "Team Name"
      }
      {
        id: "games"
        label: "Games"
      }
      {
        id: "wins"
        label: "Wins"
      }
      {
        id: "loses"
        label: "Losses"
      }
      {
        id: "catches"
        label: "Snitch Catches"
      }
      {
        id: "pointsFor"
        label: "Points For"
      }
      {
        id: "pointsAgainst"
        label: "Points Against"
      }
      {
        id: "pointDiff"
        label: "Point Difference"
      }
      {
        id: "averagePointDiff"
        label: "Average Point Difference"
      }
      {
        id: "adjustedPointDiff"
        label: "Adjusted Point Difference"
      }
      {
        id: "averageAdjustedPointDiff"
        label: "Average Adjusted Point Difference"
      }
      {
        id: "winPercent"
        label: "Win Percentage"
      }
      {
        id: "pwins"
        label: "Pythagorean Wins"
      }
      {
        id: "sos"
        label: "Strength of Schedule"
      }
    ]
    model: [
      {
        id: "name"
        label: "Team Name"
      }
      {
        id: "games"
        label: "Games"
      }
      {
        id: "wins"
        label: "Wins"
      }
      {
        id: "loses"
        label: "Losses"
      }
      {
        id: "catches"
        label: "Snitch Catches"
      }
      {
        id: "averageAdjustedPointDiff"
        label: "Average Adjusted Point Difference"
      }
      {
        id: "winPercent"
        label: "Win Percentage"
      }
      {
        id: "sos"
        label: "Strength of Schedule"
      }
    ]
    checkModel: (columnId) ->
      _.any @model, (e) -> e.id == columnId

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
