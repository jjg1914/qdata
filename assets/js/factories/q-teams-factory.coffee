qdata.factory "qTeams", ($q,$http) ->
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
