url = require 'url'
http = require 'http'
https = require 'https'

class Validator
    constructor: (@ssoBase, @serverBaseURL) ->
        @parsed = url.parse @ssoBase
        if @parsed.protocol is 'http:'
            @client = http
        else
            @client = https
    validate: (request, ticket, callback) ->
        resolvedURL = url.resolve @serverBaseURL, request.url
        parsedURL = url.parse resolvedURL, true
        delete parsedURL.query.ticket
        delete parsedURL.search
        service = url.format parsedURL
        get = @client.get
            host: @parsed.host
            port: @parsed.port
            path: url.format
                      pathname: '/validate'
                      query: 
                          ticket: ticket
                          service: service
          , (response) ->
        
                response.setEncoding 'utf8'
        
                body = ''
                response.on 'data', (chunk) ->
                    body += chunk
                    
                response.on 'end', () ->
                    lines = body.split '\n'
                    if lines.length >= 1
                        if lines[0] is 'no'
                            callback null, null
                            return
                        else if lines[0] is 'yes' &&  lines.length >= 2
                            user = id: lines[1]
                            callback user, null
                            return
            
                    callback null, new Error 'The response from the server was bad'
                    return
                    
            get.on 'error', (e) ->
                console.error e
                callback null, e
            return

exports.getMiddleware = (ssoBaseURL, serverBaseURL, options = {}) ->
    loginURL = ssoBaseURL + '/login'
    
    validator = new Validator ssoBaseURL, serverBaseURL
    
    (req, res, next) ->
        if req.session?
            if req.session.authenticatedUser?
                req.authenticatedUser = req.session.authenticatedUser
                next()
                return
  
        ticket = req.param 'ticket'
        if ticket?
            user = validator.validate req, ticket, (user, error) ->
                if req.session?
                    req.session.authenticatedUser = user
                req.authenticatedUser = user
                next()
                return
        else
          redirectURL = url.parse loginURL, true
          service = serverBaseURL + req.url
          redirectURL.query.service = service
          res.redirect url.format redirectURL
