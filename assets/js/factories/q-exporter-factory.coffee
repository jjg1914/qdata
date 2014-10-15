qdata.factory "qExporter", ($q,qAuth) ->
  google: (teams) ->
    q = $q.defer()
    title = "QData Export " + moment().format("on MM/DD/YYYY HH:mm")

    headers = [
      "Team"
      "Games"
      "Wins"
      "Losses"
      "Snitch Catches"
      "Points For"
      "Points Against"
      "Point Difference"
      "Average Point Difference"
      "Adjusted Point Difference"
      "Average Adjusted Point Difference"
      "Win Percentage"
      "Pythagorean Wins"
      "Strength of Schedule"
    ].join(",")
    data = for team in teams
      [
        team.name
        team.games
        team.wins
        team.loses
        team.catches
        team.pointsFor
        team.pointsAgainst
        team.pointDiff
        team.averagePointDiff
        team.adjustedPointDiff
        team.averageAdjustedPointDiff
        team.winPercent
        team.pwins
        team.sos
      ].join(",")

    metadata = JSON.stringify
      title: title
    csv = headers + "\r\n" + data.join("\r\n")

    boundary = '-------314159265358979323846'
    body = "\r\n--" + boundary + "\r\n" +
      "Content-Type: application/json\r\n\r\n" +
      metadata +
      "\r\n--" + boundary + "\r\n" +
      "Content-Type: text/csv\r\n\r\n" +
      csv + "\r\n--" + boundary + "--"

    qAuth.me().auth.post("/upload/drive/v2/files?convert=true",
      contentType: "multipart/mixed; boundary=\"" + boundary + "\""
      data: body
    ).done((data) ->
      q.resolve(title: title)
    ).fail ->
      q.reject()

    return q.promise
