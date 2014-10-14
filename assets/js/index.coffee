OAuth.initialize "72Zgv_nLtMNhlbe3S9UAnHIbyng"

qdata = angular.module "qdata", [
  "ngRoute"
  "ui.bootstrap"
]

qdata.config ($routeProvider) ->
  $routeProvider.when "/teams",
    templateUrl: "teams.html"
    controller: "TeamsController"
  $routeProvider.when "/games",
    templateUrl: "games.html"
    controller: "GamesController"
  $routeProvider.otherwise
    redirectTo: "/teams"

qdata.factory "auth", ($rootScope) ->
  _me =
    displayName: ""
    avatar: ""

  if localStorage["accessToken"] and !_me.auth?
    _me.auth = OAuth.create "google", access_token: localStorage["accessToken"]
    if _me.auth
      _me.auth.me().done (me) ->
        console.log me
        $rootScope.$apply ->
          _me.displayName = me.name
          _me.avatar = me.avatar

  me: -> _me

  login: ->
    OAuth.popup("google").done (result) ->
      localStorage["accessToken"] = result.access_token
      _me.auth = result
      result.me().done (me) ->
        $rootScope.$apply ->
          _me.displayName = me.name
          _me.avatar = me.avatar

  logout: ->
    delete _me.auth
    delete localStorage["accessToken"]

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
      game.date = moment(game.date).add(4, "hours").toDate()
      result.push game
    _data.resolve result

  all: -> _data.promise

qdata.factory "statsEngine", ($q,games,teams) ->
  _preRun = (runEnv,options) ->
    $q.all([teams.all(), games.all()]).then (data) ->
      q = $q.defer()
      async.series [
        (cb) -> async.each data[0], (team,cb) ->
          team = angular.copy team
          runEnv.teamCache[team.name] = runEnv.teams.length
          team._statsGames = []
          runEnv.teams.push team
          cb()
        , cb
        (cb) -> async.waterfall [
          (cb) -> async.filter data[1], (game,cb) ->
            cb(
              (!options.startDate? or
                (moment(game.date).isSame(options.startDate) or
                  moment(game.date).isAfter(options.startDate))) and
              (!options.endDate? or
                (moment(game.date).isSame(options.endDate) or
                  moment(game.date).isBefore(options.endDate))))
          , (result) -> cb null, result
          (games,cb) -> async.each games, (game,cb) ->
            game = angular.copy game
            _team0i = runEnv.teamCache[game.teams[0]]
            _team1i = runEnv.teamCache[game.teams[1]]
            game._statsTeams = [ _team0i, _team1i ]

            runEnv.teams[_team0i]._statsGames.push runEnv.games.length
            runEnv.teams[_team1i]._statsGames.push runEnv.games.length
            runEnv.games.push game

            game._statsScores = [ 0, 0 ]
            for row, i in game.scores
              for score in row
                game._statsScores[i] += score

            game._statsFinalScores = game._statsScores.slice 0
            for c in game.catches
              game._statsFinalScores[c] += 30 if c >= 0

            cb()
          , cb
        ], -> cb()
      ], -> q.resolve()
      return q.promise

  _runGames = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.games = team._statsGames.length
      cb()
    , -> q.resolve()
    return q.promise
  
  _runWins = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        _score0 = game._statsFinalScores[i]
        _score1 = game._statsFinalScores[1 - i]
        cb null, if _score0 > _score1 then m + 1 else m
      , (err,result) ->
        team.wins = result
        cb()
    , -> q.resolve()
    return q.promise

  _runLoses = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        _score0 = game._statsFinalScores[i]
        _score1 = game._statsFinalScores[1 - i]
        cb null, if _score0 < _score1 then m + 1 else m
      , (err,result) ->
        team.loses = result
        cb()
    , -> q.resolve()
    return q.promise

  _runCatches = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        count = 0
        count += 1 for c in game.catches when c == i
        cb null, m + count
      , (err,result) ->
        team.catches = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointsFor = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        cb null, m + game._statsScores[i]
      , (err,result) ->
        team.pointsFor = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointsAgainst = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, 0, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        cb null, m + game._statsScores[1 - i]
      , (err,result) ->
        team.pointsAgainst = result
        cb()
    , -> q.resolve()
    return q.promise

  _runPointDiff = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.pointDiff = team.pointsFor - team.pointsAgainst
      cb()
    , -> q.resolve()
    return q.promise

  _runAveragePointDiff = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      if team._statsGames.length > 0
        team.averagePointDiff = team.pointDiff / team._statsGames.length
      else
        team.averagePointDiff = 0
      cb()
    , -> q.resolve()
    return q.promise

  _runAdjustedPointDiff = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = runEnv.games[gamei]
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

  _runAverageAdjustedPointDiff = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      if team._statsGames.length > 0
        team.averageAdjustedPointDiff = team.adjustedPointDiff / team._statsGames.length
      else
        team.averageAdjustedPointDiff = 0
      cb()
    , -> q.resolve()
    return q.promise

  _runPWins = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = runEnv.games[gamei]
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

  _runWinPercent = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      if team.games != 0
        team.winPercent = team.wins / team.games
      else
        team.winPercent = 0
      cb()
    , -> q.resolve()
    return q.promise

  _runStatOR = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = runEnv.games[gamei]
            i = game.teams.indexOf team.name
            cb null, game.teams[1 - i]
          , cb
        (opponents,cb) ->
          async.map opponents, (opponent,cb) ->
            oppTeam = runEnv.teams[runEnv.teamCache[opponent]]
            async.waterfall [
              (cb) ->
                async.map oppTeam._statsGames, (gamei,cb) ->
                  cb null, runEnv.games[gamei]
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

  _runStatORR = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = runEnv.games[gamei]
            i = game.teams.indexOf team.name
            cb null, game.teams[1 - i]
          , cb
        (opponents,cb) ->
          async.map opponents, (opponent,cb) ->
            oppTeam = runEnv.teams[runEnv.teamCache[opponent]]
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

  _runSoS = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
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

  run: (options = {}) ->
    runEnv =
      teams: []
      games: []
      teamCache: {}
    _preRun(runEnv,options).then ->
      $q.all([
        $q.all([
          _runGames(runEnv)
          _runWins(runEnv)
        ]).then -> _runWinPercent(runEnv)
        _runLoses(runEnv)
        _runCatches(runEnv)
        _runStatOR(runEnv).then -> _runStatORR(runEnv).then -> _runSoS(runEnv)
        $q.all([
          _runPointsFor(runEnv)
          _runPointsAgainst(runEnv)
        ]).then -> _runPointDiff(runEnv).then -> _runAveragePointDiff(runEnv)
        _runAdjustedPointDiff(runEnv).then -> _runAverageAdjustedPointDiff(runEnv)
        _runPWins(runEnv)
      ])
    return runEnv.teams

qdata.filter "sprintf", ->
  (value,args...) ->
    sprintf value, args...

qdata.filter "statfmt", ->
  (value,format) ->
    if value?
      if format?
        sprintf format, value
      else
        sprintf "%s", value
    else
      ""

qdata.filter "formatDate", ->
  (value) ->
    moment(value).format("MMM Do 'YY")

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

qdata.directive "qSortable", ->
  restrict: "A"
  link: ($scope,$element,attributes) ->
    qSortable = {}
    $scope.$watch ->
      $scope.$eval attributes.qSortable
    , (newValue) ->
      qSortable = newValue
    , true

    $icon = $("<i></i>").addClass("fa").appendTo($element)

    $element.addClass "q-sortable"

    $element.click ->
      $scope.$apply ->
        if $scope.sort.field == qSortable.field
          $scope.sort.desc = !$scope.sort.desc
        else
          $scope.sort.field = qSortable.field
          $scope.sort.desc = qSortable.desc

    $scope.$watch "sort", (newValue) ->
      icon = qSortable.type || "amount"
      if newValue.field == qSortable.field
        $element.addClass "bg-info"
        $icon.removeClass "fa-sort"
        if newValue.desc
          $icon.removeClass "fa-sort-" + icon + "-asc"
          $icon.addClass "fa-sort-" + icon + "-desc"
        else
          $icon.removeClass "fa-sort-" + icon + "-desc"
          $icon.addClass "fa-sort-" + icon + "-asc"
      else
        $element.removeClass "bg-info"
        $icon.removeClass "fa-sort-" + icon + "-asc"
        $icon.removeClass "fa-sort-" + icon + "-desc"
        $icon.addClass "fa-sort"
    , true

qdata.directive "qDatepicker", ->
  restrict: 'E'
  replace: true
  scope:
    model: '=ngModel'
  template: '''
    <div class="input-group">
      <input class="form-control" type="text" datepicker-popup="dd MMMM, yyyy" is-open="isOpen" ng-model="model"></input>
      <span class="input-group-btn">
        <button type="button" class="btn btn-default" ng-click="doOpen($event)">
          <i class="fa fa-calendar"></i>
        </button>
      </span>
    </div>
  '''
  link: ($scope,$element,attributes) ->
    $scope.doOpen = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.isOpen = true


qdata.controller "TeamsController", ($scope,$filter,teams,statsEngine) ->
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
    $scope.teams = statsEngine.run
      startDate: $scope.filter.startDate
      endDate: $scope.filter.endDate
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


qdata.controller "ApplicationController", ($scope,$location,auth) ->
  $scope.navPath = ->
    $location.path()

  $scope.me = auth.me()

  $scope.login = -> auth.login()

  $scope.logout = -> auth.logout()
