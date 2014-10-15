qdata.factory "qAlerter", ($timeout) ->
  _id = 0
  _alerts = []

  _push = (alert) ->
    _id += 1
    alert.id = _id
    _alerts.unshift alert

    $timeout ->
      for e,i in _alerts when e.id == alert.id
        _alerts.splice(i,1)
    , 10000

    return undefined

  success: (options) ->
    _push
      type: "success"
      body: options.body
      title: options.title

  error: (options) ->
    _push
      type: "danger"
      body: options.body
      title: options.title

  clear: (index) ->
    _alerts.splice(index,1)

  alerts: -> _alerts
