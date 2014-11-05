qdata.filter "qRegionFormat", ->
  (value) ->
    switch value
      when "ne"
        "North East"
      when "nw"
        "North West"
      when "sw"
        "South West"
      when "s"
        "South"
      when "w"
        "West"
      when "mw"
        "Midwest"
      when "ma"
        "Mid-Atlantic"
