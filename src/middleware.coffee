
###
Middleware: Specific building blocks for controllers.
###
module.exports = (Model, opts) ->
  pre = []

  self =
    _initialize: ->
      opts = {} unless opts?
      unless Model?.collection?.name?
        opts = Model
        Model = null
      @opts = opts or {}
      @opts.Model = Model if Model?

      @middleware [
        'new'
        'create'
        'loadAll'
        'load'
        'update'
        'save'
        'redirectOnSuccess'
        'destroy'
        'redirect'
        'view'
      ]

    middleware: (props) ->
      @__middleware = props
      @_middleware prop for prop in props

    ###
    Initialize middleware.
    ###
    _middleware: (prop) ->
      fn = self[prop]
      fn = fn.bind(this)
      self[prop] = (args ...) => [
        (req, res, done) =>

          # Calculate the user settings and fill optional fields
          # with default values if necessary.
          req.resource = {} unless req.resource?
          for opt in ['key', 'name', 'plural', 'collectionName', 'Model']
            req.resource[opt] = @opts[opt] if @opts[opt]?
          if @opts.name?
            unless @opts.plural?
              req.resource.plural = "#{@opts.name}s"
          else
            name = req.resource.Model.modelName
            req.resource.name = "#{name[0].toLowerCase()}#{name[1..]}"
            unless @opts.plural?
              plural = req.resource.Model.collection.name
              req.resource.plural = "#{plural[0].toLowerCase()}#{plural[1..]}"
          unless @opts.key?
            req.resource.key = do ->
              name = req.resource.Model.modelName
              "#{name[0].toLowerCase()}#{name[1..]}"
          unless @opts.collectionName?
            req.resource.collectionName = req.resource.Model.collection.name
          done()

        fn args ...
      ]

    new: ->
      (req, res, done) =>
        res.locals[req.resource.name] = new req.resource.Model()
        done()

    create: -> [
      @new()
      @update()
    ]

    loadAll: ->
      (req, res, done) =>
        req.resource.Model.find (err, os) =>
          return done(err) if err
          res.locals[req.resource.plural] = os
          done()

    load: ->
      (req, res, done) =>
        req.resource.Model.findById req.params[req.resource.key], (err, o) =>
          return done(err) if err
          return done() unless o
          res.locals[req.resource.name] = o
          done()

    update: ->
      (req, res, done) =>
        return done() unless res.locals[req.resource.name]

        # Use a model instance as the underlaying default object and
        # extend it.
        m = new req.resource.Model()
        m[key] = value for own key, value of req.body
        o = m.toObject()
        delete o._id
        delete req.body.__v
        res.locals[req.resource.name][key] = value for own key, value of o
        done()

    save: ->
      (req, res, done) =>
        return done() unless res.locals[req.resource.name]
        res.locals[req.resource.name].save (err, o) ->
          if err
            return done(err) unless err.name is 'ValidationError'
          else
            res.locals[req.resource.name] = o
          done()

    redirectOnSuccess: (suffixes ...) ->
      (req, res, done) =>
        return done() unless res.locals[req.resource.name]?
        unless res.locals[req.resource.name].errors?
          return res.redirect(res.locals[req.resource.name], suffixes ...)
        done()

    destroy: ->
      (req, res, done) =>
        Model = req.resource.Model
        Model.findByIdAndRemove req.params[req.resource.key], (err, o) =>
          return done(err) if err
          return done() unless o?
          done()

    redirect: (path) ->
      (req, res, done) =>
        res.redirect "#{req.baseUrl}#{path}"

    view: (view, required) ->
      locals = required if typeof required is 'object'
      locals = {} unless locals?
      (req, res, done) =>
        if required
          return done() unless res.locals[req.resource.name]
        res.render view, locals

  self._initialize()
  self
