qdata.factory "qStatsEngine", ($q,qGames,qTeams) ->
  _preRun = (runEnv,options) ->
    $q.all([qTeams.all(), qGames.all()]).then (data) ->
      q = $q.defer()
      async.series [
        (cb) -> async.each data[0], (team,cb) ->
          team = angular.copy team
          runEnv.teamCache[team.name] = runEnv.teams.length
          team._statsGames = []
          team.elo = 1450
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

  _runSwim = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.waterfall [
        (cb) ->
          async.map team._statsGames, (gamei,cb) ->
            game = runEnv.games[gamei]
            i = game.teams.indexOf team.name
            scores = _.map game.scores, (e) -> _.last(e)
            pd = scores[i] - scores[1 - i]

            c = _.last game.catches
            if c >= 0
              scores[c] += 30
            win_i = if scores[0] > scores[1] then 0 else 1


            p_adj = unless pd < 0
              Math.min(pd, 80) + Math.sqrt(Math.max(pd - 80, 0))
            else
              Math.max(pd, -80) - Math.sqrt(Math.max(Math.abs(pd) - 80, 0))

            if c == win_i
              swim = unless Math.abs(p_adj) < 30
                Math.exp(-0.033 * (Math.abs(p_adj) - 20))
              else
                1
              cb null, p_adj + (30 * if i == win_i then swim else -swim)
            else
              cb null, p_adj
          , cb
        (swims,cb) ->
          async.reduce swims, 0, (m,swim,cb) ->
            cb null, m + swim
          , cb
      ], (err,result) ->
        if team._statsGames.length > 0
          team.swim = result / team._statsGames.length
        else
          team.swim = 0
        cb()
    , ->
      q.resolve()

    return q.promise

  _runSwimAdjusted = (runEnv) ->
    q = $q.defer()
    async.waterfall [
      (cb) ->
        async.map runEnv.teams, (team,cb) ->
          cb null, team.swim
        , cb
      (swims,cb) ->
        async.reduce swims, Number.MAX_VALUE, (m,v,cb) ->
          cb null, if v < m then v else m
        , cb
      (swim_min,cb) ->
        async.each runEnv.teams, (team,cb) ->
          team.swimAdjusted = team.swim - swim_min
          cb()
        , -> cb null
    ], -> q.resolve()
    return q.promise

  _runAdjustedWinPercent = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.adjustedWinPercent = ( team.winPercent + 1 ) / 2
      cb()
    , -> q.resolve()
    return q.promise

  _runPerformance = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.performance = team.swimAdjusted * team.sos * team.adjustedWinPercent
      cb()
    , -> q.resolve()
    return q.promise

  _runGamePenalty = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.gamePenalty = if team._statsGames.length < 5
        Math.sqrt(team._statsGames.length) / 2.25
      else
        1
      cb()
    , -> q.resolve()
    return q.promise

  _runOppPenalty = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, {}, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        i = game.teams.indexOf team.name
        m[game.teams[1 - i]] = true
        cb(null, m)
      , (err,result) ->
        switch _.keys(result).length
          when 0
            team.oppPenalty = 0
          when 1
            team.oppPenalty = 1 / 3
          when 2
            team.oppPenalty = 2 / 3
          else
            team.oppPenalty = 1
        cb()
    , -> q.resolve()
    return q.promise

  _runEventPenalty = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      async.reduce team._statsGames, {}, (m,gamei,cb) ->
        game = runEnv.games[gamei]
        if game.event
          m[game.event] = true
        else
          m[moment(game.date).format("YYYYMMDD")] = true
        cb(null, m)
      , (err,result) ->
        if _.keys(result).length < 2
          team.eventPenalty = 0.5
        else
          team.eventPenalty = 1
        cb()
    , -> q.resolve()
    return q.promise

  _runIQARating = (runEnv) ->
    q = $q.defer()
    async.each runEnv.teams, (team,cb) ->
      team.iqaRating = team.performance * team.gamePenalty * team.oppPenalty * team.eventPenalty
      cb()
    , -> q.resolve()
    return q.promise

  _runElo = (runEnv) ->
    q = $q.defer()
    async.waterfall [
      (cb) ->
        async.sortBy runEnv.games, (game,cb) ->
          cb(null, game.date)
        , cb
      (games,cb) ->
        async.each games, (game,cb) ->
          team0 = runEnv.teams[game._statsTeams[0]]
          team1 = runEnv.teams[game._statsTeams[1]]
          e_a = 1 / ( 1 + Math.pow(10, (team1.elo - team0.elo) / 400))
          e_b = 1 / ( 1 + Math.pow(10, (team0.elo - team1.elo) / 400))
          if game._statsFinalScores[0] > game._statsFinalScores[1]
            team0.elo += 32 * ( 1 - e_a )
            team1.elo += 32 * ( 0 - e_a )
          else
            team0.elo += 32 * ( 0 - e_a )
            team1.elo += 32 * ( 1 - e_a )
          cb()
        , cb
    ], -> q.resolve()
    return q.promise

  run: (options = {}) ->
    q = $q.defer()
    runEnv =
      teams: []
      games: []
      teamCache: {}
    _preRun(runEnv,options).then ->
      $q.all([
        $q.all([
          $q.all([
            $q.all([
              _runGames(runEnv)
              _runWins(runEnv)
            ]).then( ->
              _runWinPercent(runEnv)
            ).then ->
              _runAdjustedWinPercent(runEnv)
            _runSwim(runEnv).then -> _runSwimAdjusted(runEnv)
            _runStatOR(runEnv).then -> _runStatORR(runEnv).then -> _runSoS(runEnv)
          ]).then -> _runPerformance(runEnv)
          _runGamePenalty(runEnv)
          _runOppPenalty(runEnv)
          _runEventPenalty(runEnv)
        ]).then -> _runIQARating(runEnv)
        _runLoses(runEnv)
        _runCatches(runEnv)
        $q.all([
          _runPointsFor(runEnv)
          _runPointsAgainst(runEnv)
        ]).then -> _runPointDiff(runEnv).then -> _runAveragePointDiff(runEnv)
        _runAdjustedPointDiff(runEnv).then -> _runAverageAdjustedPointDiff(runEnv)
        _runPWins(runEnv)
        _runElo(runEnv)
      ]).then -> q.resolve(runEnv.teams)
    return q.promise
