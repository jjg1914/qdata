qdata.controller "qGamesController", ($scope,qGames) ->
  qGames.all().then (data) ->
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
