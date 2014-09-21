qdata = angular.module "qdata", []

qdata.factory "teams", ($q,$http) ->
  _data = $q.defer()
  _nameIndex = {}

  $http.get('teams.json').then (data) ->
    result = []
    for team, i in data.data
      team.id = i
      team.wins = 0
      team.loses = 0
      team.catches = 0
      team.games = 0
      team.pointsFor = 0
      team.pointsAgainst = 0
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
    games.all().then (data) ->
      for game in data
        $q.all([teams.findByName(game.teams[0]),
                teams.findByName(game.teams[1])]).then ((game_data,teams_data) ->
          console.log teams_data
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

qdata.controller "ApplicationController", ($scope,teams,statsEngine) ->
  statsEngine.run()
  teams.all().then (data) ->
    $scope.teams = data
