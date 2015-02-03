middleware = require('./middleware')

###
Predefined controllers for typical functionality.
###
module.exports = (args ...) ->
  r = middleware(args ...)

  middleware: r

  list: -> [
    r.loadAll()
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/list"
  ]

  new: -> [
    r.new()
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/edit"
  ]

  edit: -> [
    r.load()
    (req, res, done) ->
      return done() unless res.locals[req.resource.name]
      res.render "#{req.resource.collectionName}/edit"
  ]

  show: -> [
    r.load()
    (req, res, done) ->
      return done() unless res.locals[req.resource.name]
      res.render "#{req.resource.collectionName}/show"
  ]

  create: -> [
    r.create()
    r.save()
    r.redirectOnSuccess 'edit'
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/edit"
  ]

  update: -> [
    r.load()
    r.update()
    r.save()
    r.redirectOnSuccess 'edit'
    (req, res, done) ->
      return done() unless res.locals[req.resource.name]
      res.render "#{req.resource.collectionName}/edit"
  ]

  destroy: -> [
    r.destroy()
    (req, res, done) ->
      res.redirect "#{req.baseUrl}/#{req.resource.collectionName}"
  ]
