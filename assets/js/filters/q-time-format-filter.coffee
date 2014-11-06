qdata.filter "qTimeFormat", ->
  (value) ->
    seconds = value % 60
    minutes = Math.floor value / 60
    if seconds < 10
      minutes + ":0" + seconds
    else
      minutes + ":" + seconds
