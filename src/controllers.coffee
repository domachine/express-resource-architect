middleware = require('./middleware')

###
Predefined controllers for typical functionality.
###
exports = module.exports = (args ...) -> return new ControllerBundle(args ...)

class ControllerBundle
  constructor: (args ...) ->
    @middleware = middleware(args ...)

  list: -> [
    @middleware.loadAll()
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/list"
  ]

  new: -> [
    @middleware.new()
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/edit"
  ]

  edit: -> [
    @middleware.load()
    (req, res, done) ->
      return done() unless res.locals[req.resource.key]
      res.render "#{req.resource.collectionName}/edit"
  ]

  show: -> [
    @middleware.load()
    (req, res, done) ->
      return done() unless res.locals[req.resource.key]
      res.render "#{req.resource.collectionName}/show"
  ]

  create: -> [
    @middleware.create()
    @middleware.save()
    @middleware.redirectOnSuccess 'edit'
    (req, res, done) ->
      res.render "#{req.resource.collectionName}/edit"
  ]

  update: -> [
    @middleware.load()
    @middleware.update()
    @middleware.save()
    @middleware.redirectOnSuccess 'edit'
    (req, res, done) ->
      return done() unless res.locals[req.resource.key]
      res.render "#{req.resource.collectionName}/edit"
  ]

  destroy: -> [
    @middleware.destroy()
    (req, res, done) ->
      res.redirect "#{req.baseUrl}/#{req.resource.collectionName}"
  ]

exports.ControllerBundle = ControllerBundle
