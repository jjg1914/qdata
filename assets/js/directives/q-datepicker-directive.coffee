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
