qdata.factory "qGames", ($q,$http) ->
  _data = $q.defer()

  $http.get('games.json').then (data) ->
    result = []
    for game, i in data.data
      game.id = i
      game.date = moment(game.date).add(4, "hours").toDate()
      result.push game
    _data.resolve result

  all: -> _data.promise
