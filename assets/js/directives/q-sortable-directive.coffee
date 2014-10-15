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
