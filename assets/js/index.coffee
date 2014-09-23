qdata = angular.module "qdata", [ "ngRoute", "ngTable" ]

qdata.config ($routeProvider) ->
  $routeProvider.when "/teams",
    templateUrl: "teams.html"
    controller: "TeamsController"
  $routeProvider.when "/games",
    templateUrl: "games.html"
    controller: "GamesController"
  $routeProvider.otherwise
    redirectTo: "/teams"

qdata.factory "teams", ($q,$http) ->
  _data = $q.defer()
  _nameIndex = {}

  $http.get('teams.json').then (data) ->
    result = []
    for team, i in data.data
      _nameIndex[team.name] = i
      result.push team
    _data.resolve result

  all: -> _data.promise

  findByName: (name) ->
    _data.promise.then (data) ->
      idx = _nameIndex[name]
      if idx
        data[idx]

qdata.factory "games", ($q,$http) ->
  _data = $q.defer()

  $http.get('games.json').then (data) ->
    result = []
    for game, i in data.data
      game.id = i
      result.push game
    _data.resolve result

  all: -> _data.promise

qdata.factory "statsEngine", ($q,games,teams) ->
  run: ->
    teams.all().then (all_teams) ->
      for team in all_teams
        team.wins = 0
        team.loses = 0
        team.catches = 0
        team.games = 0
        team.pointsFor = 0
        team.pointsAgainst = 0
        team.pointDiff = 0
      games.all().then (data) ->
        $q.all( for game in data
          $q.all([teams.findByName(game.teams[0]),
                  teams.findByName(game.teams[1])]).then ((game_data,teams_data) ->
            tmpScores = [ 0, 0 ]
            for row,i in game_data.scores
              for s in row
                tmpScores[i] += s

            team.games += 1 for team in teams_data

            team.pointsFor += tmpScores[i] for team,i in teams_data
            team.pointsAgainst += tmpScores[1 - i] for team,i in teams_data

            for c in game_data.catches
              tmpScores[c] += 30
              teams_data[c].catches += 1
            if tmpScores[0] > tmpScores[1]
              teams_data[0].wins += 1
              teams_data[1].loses += 1
            else
              teams_data[0].loses += 1
              teams_data[1].wins += 1
          ).bind(this,game)
        ).then ->
          teams.all().then (teams_data) ->
            for team in teams_data
              team.pointDiff = team.pointsFor - team.pointsAgainst

qdata.filter "formatDate", ->
  (value) ->
    moment(value, "YYYY-MM-DD").format("MMM Do 'YY")

qdata.filter "formatFinalScore", ->
  (value,index) ->
    score = 0
    for s in value.scores[index]
      score += s
    score += 30 for c in value.catches when c == index
    return score

qdata.filter "formatScore", ->
  (value,index,period) ->
    if period < value.scores[index].length
      result = value.scores[index][period]
      result += "(+30)" if value.catches[period] == index
      result
    else
      ""

qdata.filter "formatRegion", ->
  (value) ->
    switch value
      when "ne"
        "North East"
      when "nw"
        "North West"
      when "sw"
        "South West"
      when "s"
        "South"
      when "w"
        "West"
      when "mw"
        "Midwest"
      when "ma"
        "Mid-Atlantic"

qdata.directive "qGameFinalScore", ->
  replace: true
  restrict: "E"
  scope:
    qGame: "="
    qTeamIndex: "="
  template: """
    <span ng-class="{'text-success': isWinner, 'text-danger': isLoser}">
      {{ score }}
    </span>
    """
  link: ($scope) ->
    $scope.score = 0
    for score in $scope.qGame.scores[$scope.qTeamIndex]
      $scope.score += score
    $scope.score += 30 for c in $scope.qGame.catches when c == $scope.qTeamIndex

qdata.controller "TeamsController", ($scope,$filter,ngTableParams,teams,statsEngine) ->
  statsEngine.run().then ->
    $scope.tableParams.reload()

  $scope.minimumGames = 1
  $scope.region = "all"

  $scope.tableParams = new ngTableParams { page: 1, count: 1024 },
    total: 1
    counts: [],
    getData: ($defer,params) ->
      teams.all().then (data) ->
        params.total(data.length)

        data = $filter("filter") data, (value) ->
          value.games >= $scope.minimumGames &&
          ( $scope.region == "all" || value.region == $scope.region )

        data = if params.sorting()
          $filter("orderBy")(data, params.orderBy())
        else
          data

        $defer.resolve(data)

  $scope.$watch "minimumGames", ->
    $scope.tableParams.reload()

  $scope.$watch "region", ->
    $scope.tableParams.reload()

qdata.controller "GamesController", ($scope,games) ->
  games.all().then (data) ->
    $scope.games = data

    tmp = {}
    for game in data
      tmp[game.event] = true
    $scope.events = ( k for k,v of tmp )
    $scope.event = "all"

    $scope.gameFilter = (game) ->
      $scope.event == "all" or game.event == $scope.event

qdata.controller "ApplicationController", ($scope,$location) ->
  $scope.navPath = ->
    $location.path()
