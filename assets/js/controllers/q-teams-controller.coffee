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
        enabled: true
        group: "Standard"
      }
      {
        id: "games"
        label: "Games"
        enabled: true
        group: "Standard"
      }
      {
        id: "wins"
        label: "Wins"
        enabled: true
        group: "Standard"
      }
      {
        id: "loses"
        label: "Losses"
        enabled: true
        group: "Standard"
      }
      {
        id: "catches"
        label: "Snitch Catches"
        enabled: true
        group: "Standard"
      }
      {
        id: "pointsFor"
        label: "Points For"
        group: "Score"
      }
      {
        id: "pointsAgainst"
        label: "Points Against"
        group: "Score"
      }
      {
        id: "pointDiff"
        label: "Point Difference"
        group: "Score"
      }
      {
        id: "averagePointDiff"
        label: "Average Point Difference"
        group: "Score"
      }
      {
        id: "adjustedPointDiff"
        label: "Adjusted Point Difference"
        group: "Score"
      }
      {
        id: "averageAdjustedPointDiff"
        label: "Average Adjusted Point Difference"
        enabled: true
        group: "Score"
      }
      {
        id: "winPercent"
        label: "Win Percentage"
        enabled: true
        group: "Standard"
      }
      {
        id: "pwins"
        label: "Pythagorean Wins"
        group: "Rating"
      }
      {
        id: "swim"
        label: "Snitch When it Matters"
        enabled: true
        group: "Rating"
      }
      {
        id: "swimAdjusted"
        label: "Adjusted Snitch When it Matters"
        group: "Rating"
      }
      {
        id: "sos"
        label: "Strength of Schedule"
        enabled: true
        group: "Rating"
      }
      {
        id: "performance"
        label: "IQA Rating"
      }
      {
        id: "iqaRating"
        label: "IQA Modifed Rating"
        enabled: true
      }
      {
        id: "elo"
        label: "ELO Rating"
        enabled: true
      }
    ]
    checkModel: (columnId) ->
      _.any @model, (e) -> e.id == columnId

  $scope.columns.model = _.filter $scope.columns.data, (e) -> e.enabled

  $scope.filter =
    games: 1
    region: "all"
    name: ""
    startDate: moment("2014-09-01").toDate()
    endDate: moment().toDate()

  $scope.sort =
    field: "iqaRating"
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
