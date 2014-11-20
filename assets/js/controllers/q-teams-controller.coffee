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
      groupByTextProvider: (group) ->
        switch group
          when 0
            "Standard"
          when 1
            "Score"
          when 2
            "Rating"
    data: [
      {
        id: "name"
        label: "Team Name"
        enabled: true
        group: 0
      }
      {
        id: "games"
        label: "Games"
        enabled: true
        group: 0
      }
      {
        id: "wins"
        label: "Wins"
        enabled: true
        group: 0
      }
      {
        id: "loses"
        label: "Losses"
        enabled: true
        group: 0
      }
      {
        id: "catches"
        label: "Snitch Catches"
        enabled: true
        group: 0
      }
      {
        id: "pointsFor"
        label: "Points For"
        group: 1
      }
      {
        id: "pointsAgainst"
        label: "Points Against"
        group: 1
      }
      {
        id: "pointDiff"
        label: "Point Difference"
        group: 1
      }
      {
        id: "averagePointDiff"
        label: "Average Point Difference"
        group: 1
      }
      {
        id: "adjustedPointDiff"
        label: "Adjusted Point Difference"
        group: 1
      }
      {
        id: "averageAdjustedPointDiff"
        label: "Average Adjusted Point Difference"
        enabled: true
        group: 1
      }
      {
        id: "winPercent"
        label: "Win Percentage"
        enabled: true
        group: 0
      }
      {
        id: "pwins"
        label: "Pythagorean Wins"
        group: 2
      }
      {
        id: "swim"
        label: "Snitch When it Matters"
        enabled: true
        group: 2
      }
      {
        id: "swimAdjusted"
        label: "Adjusted Snitch When it Matters"
        group: 2
      }
      {
        id: "sos"
        label: "Strength of Schedule"
        enabled: true
        group: 2
      }
      {
        id: "performance"
        label: "IQA Rating"
        group: 2
      }
      {
        id: "iqaRating"
        label: "IQA Modifed Rating"
        enabled: true
        group: 2
      }
      {
        id: "elo"
        label: "ELO Rating"
        enabled: true
        group: 2
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
