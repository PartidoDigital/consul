App.Votes =

  hoverize: (votes) ->
    $(document).on {
      'mouseenter focus': ->
        $("div.participation-not-allowed", this).show()
        $("div.participation-allowed", this).hide()
      mouseleave: ->
        $("div.participation-not-allowed", this).hide()
        $("div.participation-allowed", this).show()
      touchstart: ->
        $("div.participation-not-allowed").hide()
        $("div.participation-not-allowed", this).show()
        $("div.participation-allowed", this).hide()
    }, votes

  initialize: ->
    App.Votes.hoverize "div.votes"
    App.Votes.hoverize "div.supports"
    App.Votes.hoverize "div.debate-questions"
    App.Votes.hoverize "div.comment-footer"
    App.Votes.hoverize "div.poll-question-answer-access"
    false
