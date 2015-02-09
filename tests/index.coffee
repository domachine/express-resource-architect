_ = require('highland')
mongoose = require('mongoose')
chai = require('chai')
chai.use require('sinon-chai')
sinon = require('sinon')
express = require('express')

architect = require('../src')

should = chai.should()

before ->
  @Employee = mongoose.model('Employee',
    name: String
    reference:
      type: mongoose.Schema.Types.ObjectId
      required: true
  )

  @testMiddleware = (req, res, fns, done) ->
    res.locals = {} unless res.locals?
    _ fns
    .flatten()
    .nfcall([req, res])
    .series()
    .collect()
    .stopOnError done
    .each ->
      done null, req, res

beforeEach ->
  @controllers =
    list: ->
    new: ->
    edit: ->
    create: ->
    update: ->
    destroy: ->
    partialUpdate: ->
    show: ->

  @app =
    __handlers:
      get: {}
      post: {}
      put: {}
      delete: {}
      patch: {}

    use: sinon.spy (f) ->
      @useFunc = f

    get: sinon.spy (u, f) ->
      @__handlers.get[u] = f

    post: sinon.spy (u, f) ->
      @__handlers.get[u] = f

    put: sinon.spy (u, f) ->
      @__handlers.put[u] = f

    delete: sinon.spy (u, f) ->
      @__handlers.delete[u] = f

    patch: sinon.spy (u, f) ->
      @__handlers.patch[u] = f

  @checkInitialization = (name, plural) ->
    @app.use.should.have.been.calledOnce

    @app.get.should.have.callCount 4
    @app.get.should.have.been.calledWith "/#{plural}"
    @app.get.args[0][1][1].should.equal @controllers.list
    @app.get.should.have.been.calledWith "/#{plural}/new"
    @app.get.args[1][1][1].should.equal @controllers.new
    @app.get.should.have.been.calledWith "/#{plural}/:#{name}"
    @app.get.args[2][1][1].should.equal @controllers.show
    @app.get.should.have.been.calledWith "/#{plural}/:#{name}/edit"
    @app.get.args[3][1][1].should.equal @controllers.edit

    @app.post.should.have.been.calledOnce
    @app.post.should.have.been.calledWith "/#{plural}"
    @app.post.args[0][1][1].should.equal @controllers.create

    @app.put.should.have.been.calledOnce
    @app.put.should.have.been.calledWith "/#{plural}/:#{name}"
    @app.put.args[0][1][1].should.equal @controllers.update

    @app.delete.should.have.been.calledOnce
    @app.delete.should.have.been.calledWith "/#{plural}/:#{name}"
    @app.delete.args[0][1][1].should.equal @controllers.destroy

    @app.patch.should.have.been.calledOnce
    @app.patch.should.have.been.calledWith "/#{plural}/:#{name}"
    @app.patch.args[0][1][1].should.equal @controllers.partialUpdate

describe 'router', ->
  it 'should load all controllers', ->
    controllers = @controllers

    resource = architect(@app)
    resource 'user', controllers

    @checkInitialization 'user', 'users'

  it 'should load model controllers', ->
    resource = architect(@app)
    resource @Employee, @controllers

    @app.use.should.have.been.calledOnce

    @checkInitialization 'employee', 'employees'

  it 'should load resource information', (done) ->
    resource = architect(@app)
    resource @Employee, @controllers

    @app.use.should.have.been.calledOnce

    @checkInitialization 'employee', 'employees'

    req = {}
    res =
      locals: {}

    @app.__handlers.get['/employees'][0] req, res, =>
      should.exist req.resource
      req.resource.name.should.equal 'employee'
      req.resource.plural.should.equal 'employees'
      req.resource.Model.should.equal @Employee
      done()
