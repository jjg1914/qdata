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
  _teams = []
  _games = []
  _teamCache = {}

  _preRun = ->
    _teams.length = 0
    _games.length = 0
    $q.all([teams.all(), games.all()]).then (data) ->
      q = $q.defer()
      async.series [
        (cb) -> async.each data[0], (team,cb) ->
          _teamCache[team.name] = _teams.length
          team._statsGames = []
          _teams.push team

          cb()
        , cb
        (cb) -> async.each data[1], (game,cb) ->
          _team0i = _teamCache[game.teams[0]]
          _team1i = _teamCache[game.teams[1]]
          game._statsTeams = [ _team0i, _team1i ]

          _teams[_team0i]._statsGames.push _games.length
          _teams[_team1i]._statsGames.push _games.length
          _games.push game

          game._statsScores = [ 0, 0 ]
          for row, i in game.scores
            for score in row
              game._statsScores[i] += score

          game._statsFinalScores = game._statsScores.slice 0
          for c in game.catches
            game._statsFinalScores[c] += 30 if c >= 0

          cb()
        , cb
      ], -> q.resolve()
      return q.promise

  _runGames = ->
    teams.all().then (teams) ->
      q = $q.defer()
      async.each teams, (team,cb) ->
        team.games = team._statsGames.length
        cb()
      , q.resolve()
      return q.promise
  
  _runWins = ->
    teams.all().then (teams) ->
      q = $q.defer()
      async.each teams, (team,cb) ->
        async.reduce team._statsGames, 0, (m,gamei,cb) ->
          game = _games[gamei]
          i = game.teams.indexOf team.name
          _score0 = game._statsFinalScores[i]
          _score1 = game._statsFinalScores[1 - i]
          cb null, if _score0 > _score1 then m + 1 else m
        , (err,result) ->
          team.wins = result
          cb()
      , -> q.resolve()
      return q.promise

  _runLoses = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = _games[gamei]
        i = game.teams.indexOf team.name
        _score0 = game._statsFinalScores[i]
        _score1 = game._statsFinalScores[1 - i]
        cb null, if _score0 < _score1 then m + 1 else m
      , (err,result) ->
        team.loses = result
        cb()
    , -> q.resolve()
    return q.promise

  _runCatches = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = _games[gamei]
        i = game.teams.indexOf team.name
        count = 0
        count += 1 for c in game.catches when c == i
        cb null, m + count
      , (err,result) ->
        team.catches = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointsFor = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = _games[gamei]
        i = game.teams.indexOf team.name
        cb null, m + game._statsScores[i]
      , (err,result) ->
        team.pointsFor = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointsAgainst = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = _games[gamei]
        i = game.teams.indexOf team.name
        cb null, m + game._statsScores[1 - i]
      , (err,result) ->
        team.pointsAgainst = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointDiff = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      team.pointDiff = team.pointsFor - team.pointsAgainst
      cb()
    , -> q.resolve()
    return q.promise

  _runAveragePointDiff = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      if team._statsGames.length > 0
        team.averagePointDiff = team.pointDiff / team._statsGames.length
      else
        team.averagePointDiff = 0
      cb()
    , -> q.resolve()
    return q.promise

  _runAdjustedPointDiff = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = _games[gamei]
            i = game.teams.indexOf team.name
            pf = game._statsScores[i]
            pa = game._statsScores[1 - i]
            cb null, Math.max(Math.min(pf - pa, 120), -120)
          , cb
        (qpds,cb) ->
          async.reduce qpds, 0, (m,qpd,cb) ->
            cb null, m + qpd
          , cb
      ], (err,result) ->
        team.adjustedPointDiff = result
        cb()
    , -> q.resolve()
    return q.promise

  _runAverageAdjustedPointDiff = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      if team._statsGames.length > 0
        team.averageAdjustedPointDiff = team.adjustedPointDiff / team._statsGames.length
      else
        team.averageAdjustedPointDiff = 0
      cb()
    , -> q.resolve()
    return q.promise


  _runPWins = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = _games[gamei]
            i = game.teams.indexOf team.name
            cb null, [ game._statsScores[i], game._statsScores[1 - i] ]
          , cb
        (pds,cb) ->
          async.reduce pds, [ 0, 0 ], (m,pd,cb) ->
            cb null, [ m[0] + pd[0], m[1] + pd[1] ]
          , cb
      ], (err,result) ->
        team.pwins = team._statsGames.length * ( 1 / ( 1 + Math.pow( result[1] / result[0], 1.83 ) ) )
        cb()
    , -> q.resolve()
    return q.promise

  _runWinPercent = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      if team.games != 0
        team.winPercent = team.wins / team.games
      else
        team.winPercent = 0
      cb()
    , -> q.resolve()
    return q.promise

  _runStatOR = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = _games[gamei]
            i = game.teams.indexOf team.name
            cb null, game.teams[1 - i]
          , cb
        (opponents,cb) ->
          async.map opponents, (opponent,cb) ->
            oppTeam = _teams[_teamCache[opponent]]
            async.waterfall [
              (cb) ->
                async.map oppTeam._statsGames, (gamei,cb) ->
                  cb null, _games[gamei]
                , cb
              (oppGames,cb) ->
                async.filter oppGames, (game,cb) ->
                  cb game.teams.indexOf(team.name) == -1
                , (result) -> cb null, result
              (oppGames,cb) ->
                async.filter oppGames, (game,cb) ->
                  i = game.teams.indexOf oppTeam.name
                  score0 = game._statsFinalScores[i]
                  score1 = game._statsFinalScores[1 - i]
                  cb score0 > score1
                , (result) -> cb null, result.length, oppGames.length
            ], (err,oppWins,oppGames) -> cb null, [ oppWins, oppGames ]
          , cb
        (opponentWins,cb) ->
          async.reduce opponentWins, [ 0, 0 ], (m,opponentWin,cb) ->
            cb null, [ m[0] + opponentWin[0], m[1] + opponentWin[1] ]
          , cb
      ], (err,result) ->
        team._statOR = result
        cb()
    , -> q.resolve()
    return q.promise

  _runStatORR = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = _games[gamei]
            i = game.teams.indexOf team.name
            cb null, game.teams[1 - i]
          , cb
        (opponents,cb) ->
          async.map opponents, (opponent,cb) ->
            oppTeam = _teams[_teamCache[opponent]]
            cb null, oppTeam._statOR
          , cb
        (opponentORs,cb) ->
          async.reduce opponentORs, [ 0, 0 ], (m,opponentOR,cb) ->
            cb null, [ m[0] + opponentOR[0], m[1] + opponentOR[1] ]
          , cb
      ], (err,result) ->
        team._statORR = result
        cb()
    , -> q.resolve()
    return q.promise

  _runSoS = ->
    q = $q.defer()
    async.each _teams, (team,cb) ->
      _oppW = if team._statOR[1] != 0
        team._statOR[0] / team._statOR[1]
      else
        0
      _oppOppW = if team._statORR[1] != 0
        team._statORR[0] / team._statORR[1]
      else
        0
      team.sos = ( ( 2 * _oppW ) + _oppOppW ) / 3
      cb()
    , -> q.resolve()
    return q.promise

  run: ->
    _preRun().then ->
      $q.all([
        $q.all([
          _runGames()
          _runWins()
        ]).then -> _runWinPercent()
        _runLoses()
        _runCatches()
        _runStatOR().then -> _runStatORR().then -> _runSoS()
        $q.all([
          _runPointsFor()
          _runPointsAgainst()
        ]).then -> _runPointDiff().then -> _runAveragePointDiff()
        _runAdjustedPointDiff().then -> _runAverageAdjustedPointDiff()
        _runPWins()
      ])

qdata.filter "sprintf", ->
  (value,args...) ->
    sprintf value, args...

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

qdata.directive "qTh", ->
  restrict: "A"
  link: ($scope,$element,attributes) ->
    qField = undefined

    $scope.$watch ->
      $scope.$eval attributes.qTh
    , (newValue) ->
      qField = newValue

    $element.addClass "sortable"

    $scope.$watch ->
      $scope.tableParams.isSortBy qField, "asc"
    , (newValue) ->
      if newValue
        $element.addClass "sort-asc"
      else
        $element.removeClass "sort-asc"

    $scope.$watch ->
      $scope.tableParams.isSortBy qField, "desc"
    , (newValue) ->
      if newValue
        $element.addClass "sort-asc"
      else
        $element.removeClass "sort-asc"

    $element.click ->
      options = {}
      options[qField] = if $scope.tableParams.isSortBy qField, 'asc'
        'desc'
      else
        'asc'
      $scope.$apply ->
        $scope.tableParams.sorting options

qdata.controller "TeamsController", ($scope,$filter,ngTableParams,teams,statsEngine) ->
  statsEngine.run().then ->
    $scope.tableParams.reload()
    $scope.tableParams.sorting wins: "desc"

  $scope.filter =
    games: 1
    region: "all"
    name: ""

  $scope.tableParams = new ngTableParams { page: 1, count: 1024 },
    total: 1
    counts: [],
    getData: ($defer,params) ->
      teams.all().then (data) ->
        params.total(data.length)

        data = $filter("filter") data, (value) ->
          gameFilter = value.games >= $scope.filter.games
          regionFilter = $scope.filter.region == "all" || value.region == $scope.filter.region
          nameFilter = value.name.toLowerCase().indexOf($scope.filter.name.toLowerCase()) >= 0
          
          gameFilter && regionFilter && nameFilter

        data = if params.sorting()
          $filter("orderBy")(data, params.orderBy())
        else
          data

        $defer.resolve(data)

  $scope.$watch "filter.games", ->
    $scope.tableParams.reload()
  $scope.$watch "filter.name", ->
    $scope.tableParams.reload()

qdata.controller "GamesController", ($scope,games) ->
  games.all().then (data) ->
    $scope.games = data

    tmp = {}
    for game in data when game.event?
      tmp[game.event] = true
    $scope.events = ( k for k,v of tmp )
    $scope.filter =
      event: "all"
      team: ""

    $scope.gameFilter = (game) ->
      nameFilter = (team for team in game.teams when team.toLowerCase().indexOf($scope.filter.team.toLowerCase()) >= 0)
      ( $scope.filter.event == "all" or game.event == $scope.filter.event ) and nameFilter.length > 0


qdata.controller "ApplicationController", ($scope,$location) ->
  $scope.navPath = ->
    $location.path()
