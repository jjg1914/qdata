qdata.filter "qFinalScoreFormat", ->
  (value,index) ->
    score = 0
    for s in value.scores[index]
      score += s
    score += 30 for c in value.catches when c == index
    return score
