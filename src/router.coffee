log = require('util').log

###
Main resource router.
###
module.exports = (app) ->

  ###
  Overload redirect function.
  ###
  app.use (req, res, done) ->
    __redirect = res.redirect
    res.redirect = (object, suffixes ...) ->
      return __redirect.apply(this, arguments) unless object.collection?
      path = "#{req.baseUrl}/#{object.collection.name}/#{object._id}"
      path += "/#{suffix}" for suffix in suffixes
      __redirect.call this, path
    done()

  (name, plural, controllers) ->
    actions = [
      'list'
      'new'
      'show'
      'edit'
      'create'
      'update'
      'partialUpdate'
      'destroy'
    ]
    Model = null

    if typeof plural is 'object'
      controllers = plural
      plural = null
    if name.collection?.name?
      unless plural?
        plural = name.collection.name
      Model = name
      name = name.modelName
      name = "#{name[0].toLowerCase()}#{name[1..]}"
    else
      unless plural?
        plural = "#{name}s"

    route = (method, path, controller) ->
      app[method] "/#{plural}#{path}", [
        (req, res, done) ->
          req.resource =
            name: name
            plural: plural
            Model: Model
          done()

        controller
      ]

    if controllers.new and not controllers.create
      log "[WARN] resource #{plural} has 'new' controller but no 'create' controller!"

    if controllers.edit and not controllers.update
      log "[WARN] resource #{plural} has 'edit' controller but no 'update' controller!"

    for action in actions
      if controllers[action]?
        switch action
          when 'list' then route 'get', '', controllers[action]
          when 'new' then route 'get', '/new', controllers[action]
          when 'show' then route 'get', "/:#{name}", controllers[action]
          when 'edit' then route 'get', "/:#{name}/edit", controllers[action]
          when 'create' then route 'post', '', controllers[action]
          when 'update' then route 'put', "/:#{name}", controllers[action]
          when 'partialUpdate'
            route 'patch', "/:#{name}", controllers[action]
          when 'destroy' then route 'delete', "/:#{name}", controllers[action]
