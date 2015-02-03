
###
Middleware: Specific building blocks for controllers.
###
module.exports = (Model, opts) ->

  self =
    _initialize: ->
      if Model? or opts?
        {key, name, plural, collectionName} = (opts or {})
        unless key?
          key = Model.modelName
          key = "#{key[0].toLowerCase()}#{key[1..]}"
        collectionName = Model.collection.name unless collectionName?
        unless plural?
          if name?
            plural = "#{name}s"
          else
            plural = collectionName
        name = key unless name?

        @Model = Model
        @key = key
        @name = name
        @plural = plural
        @collectionName = collectionName

      @_middleware 'new'
      @_middleware 'create'
      @_middleware 'loadAll'
      @_middleware 'load'
      @_middleware 'update'
      @_middleware 'save'
      @_middleware 'redirectOnSuccess'
      @_middleware 'destroy'
      @_middleware 'redirect'
      @_middleware 'view'

    ###
    Initialize middleware.
    ###
    _middleware: (key) ->
      fn = self[key]
      fn = fn.bind(self)
      self[key] = (args ...) -> [
        (req, res, done) =>
          unless req.resource?
            req.resource =
              name: @name
              plural: @plural
              Model: @Model

          if @key
            req.resource.key = @key
          else
            req.resource.key = req.resource.name
          if @collectionName
            req.resource.collectionName = @collectionName
          else
            req.resource.collectionName = req.resource.plural
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
        req.body[key] = value for own key, value of o
        delete req.body._id
        delete req.body.__v
        res.locals[req.resource.name][key] = value \
          for own key, value of req.body
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
