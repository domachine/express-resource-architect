middleware = require('./middleware')

###
Predefined controllers for typical functionality.
###
module.exports = (args ...) ->
  r = middleware(args ...)

  middleware: r

  list: -> [
    r.loadAll()
    r.view "#{r.collectionName}/list"
  ]

  new: -> [
    r.new()
    r.view "#{r.collectionName}/edit"
  ]

  edit: -> [
    r.load()
    r.view "#{r.collectionName}/edit", true
  ]

  show: -> [
    r.load()
    r.view "#{r.collectionName}/show", true
  ]

  create: -> [
    r.create()
    r.save()
    r.redirectOnSuccess 'edit'
    r.view "#{r.collectionName}/edit", true
  ]

  update: -> [
    r.load()
    r.update()
    r.save()
    r.redirectOnSuccess 'edit'
    r.view "#{r.collectionName}/edit", true
  ]

  destroy: -> [
    r.destroy()
    r.redirect "/#{r.collectionName}"
  ]
