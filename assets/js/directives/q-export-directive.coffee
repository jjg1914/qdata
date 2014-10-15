qdata.directive "qExport", (qExporter,qAlerter,qAuth) ->
  restrict: 'E'
  replace: true
  scope: true
  template: '''
    <div class="btn-group">
      <a class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">
        <i class="fa fa-download"></i>
        Export
        <i class="fa fa-spinner q-spin" ng-show="exporting"></i>
        <span class="caret"></span>
      </a>
      <ul class="dropdown-menu" role="menu">
        <li ng-class="{ disabled: !me.auth }">
          <a href="" ng-click="exportGooogle()">
            <i class="fa fa-google"></i>
            Google Docs
          </a>
        </li>
      </ul>
    </div>
  '''
  link: ($scope,$element,attributes) ->
    $scope.me = qAuth.me()

    $scope.exporting = false

    $scope.qExportData = []
    $scope.$watchCollection ->
      $scope.$eval attributes.qExportData
    , (newValue) ->
      $scope.qExportData = newValue

    $scope.exportGooogle = ->
      $scope.exporting = true
      qExporter.google($scope.qExportData).then((data) ->
        qAlerter.success
          title: "Export completed!"
          body: "Successfully exported Google Doc: \"" + data.title + "\""
      ).catch(->
        qAlerter.error
          title: "Export failed!"
          body: "Error exporting to Google Doc"
      ).finally ->
        $scope.exporting = false
