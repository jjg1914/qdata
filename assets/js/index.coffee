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
            tmpScores = game_data.scores.slice 0

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

qdata.filter "formatScore", ->
  (value,index) ->
    sufix = ""
    score = value.scores[index]
    for c, i in value.catches
      if c == index
        score += 30
        switch i
          when 0
            sufix += "*"
          when 1
            sufix += "^"
          when 3
            sufix += "!"
    score + sufix

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

qdata.controller "ApplicationController", ($scope,$location) ->
  $scope.navPath = ->
    $location.path()
