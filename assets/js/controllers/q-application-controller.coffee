qdata.controller "qApplicationController", ($scope,$location,qAuth,qAlerter) ->
  $scope.navPath = ->
    $location.path()

  $scope.me = qAuth.me()

  $scope.login = -> qAuth.login()

  $scope.logout = -> qAuth.logout()

  $scope.alerts = qAlerter.alerts()

  $scope.closeAlert = (index) ->
    qAlerter.clear(index)
