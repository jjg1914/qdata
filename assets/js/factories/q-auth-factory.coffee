qdata.factory "qAuth", ($rootScope) ->
  _me =
    displayName: ""
    avatar: ""

  if localStorage["accessToken"] and !_me.auth?
    _me.auth = OAuth.create "google", access_token: localStorage["accessToken"]
    if _me.auth
      _me.auth.me().done (me) ->
        $rootScope.$apply ->
          _me.displayName = me.name
          _me.avatar = me.avatar

  me: -> _me

  login: ->
    OAuth.popup("google").done (result) ->
      localStorage["accessToken"] = result.access_token
      _me.auth = result
      result.me().done (me) ->
        $rootScope.$apply ->
          _me.displayName = me.name
          _me.avatar = me.avatar

  logout: ->
    delete _me.auth
    delete localStorage["accessToken"]
