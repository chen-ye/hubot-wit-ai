# Description
#   A hubot wit.ai router
#
# Configuration:
#   HUBOT_WIT_TOKEN
#
# Commands:
#   hey hubot (hey hubot,) <dialog> - Ask me something. I may or may not understand you.
# hubot hey (hubot hey,) <dialog> - Ask me something. I may or may not understand you.
#
# Notes:
#   response from wit.ai will trigger event with intent as the event name and entities in JSON object as parameters
#
# Author:
#   tianwei.liu <tianwei.liu@target.com>

Wit = require('node-wit').Wit
immersive = if process.env.HUBOT_WIT_IMMERSIVE is 'true' then true else false

module.exports = (robot) ->
  
  actions = {
    say: (sessionId, msg, cb) ->
      robot.logger.debug msg
      cb()
    ,
    merge: (context, entities, cb) -> 
      cb context
    ,
    error: (sessionid, msg) -> 
      robot.logger.error 'Oops, I don\'t know what to do.'
    ,
    'wait': (context, cb) -> 
      cb context
  }
  
  unless process.env.HUBOT_WIT_TOKEN?
    robot.send "i am not on wit's friendlist yet. :("
    robot.logger.error "HUBOT_WIT_TOKEN not set"
  else
    wit = new Wit(process.env.HUBOT_WIT_TOKEN, actions, robot.logger)
    
    
    
  robot.respond /hey(, | )(.*)/i, (res) ->
    query = res.match[2]
    robot.logger.debug "query: #{query}"
    askWit query, res

  robot.hear ///hey\s+#{robot.name}(,\s+|\s+)(.*)///i, (res) ->
    query = res.match[2]
    robot.logger.debug "query: #{query}"
    askWit query, res
    
  robot.hear /.*/i, (res) ->
    if immersive
      query = res.match[0]
      console.log "query: #{query}"
      askWit query, res

  askWit = (query, res) ->
    unless res.envelope.user.wit?
      res.envelope.user.wit = {context: {}}
    else unless res.envelope.user.wit.context?
      res.envelope.user.wit.context = {}

    wit_callback = (error, data) ->
      if error 
        robot.logger.debug('Wit error: #{error}')
      else 
        if data.msg?
          res.send data.msg
        if data.action?
            robot.emit "#{data.action}",
            {
              res: res
              entities: data.entities
              msg: data.msg
            }
        if data.entities?
          res.envelope.user.wit.context.entities = data.entities

    wit.converse res.envelope.user, query, res.envelope.user.wit.context, wit_callback
