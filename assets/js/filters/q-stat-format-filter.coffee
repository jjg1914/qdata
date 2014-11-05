qdata.filter "qStatFormat", ->
  (value,format) ->
    if value?
      if format?
        sprintf format, value
      else
        sprintf "%s", value
    else
      ""
