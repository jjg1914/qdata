qdata.filter "qDateFormat", ->
  (value) ->
    moment(value).format("MMM Do 'YY")
