qdata.config ($routeProvider) ->
  $routeProvider.when "/teams",
    templateUrl: "teams.html"
    controller: "qTeamsController"
  $routeProvider.when "/games",
    templateUrl: "games.html"
    controller: "qGamesController"
  $routeProvider.otherwise
    redirectTo: "/teams"
