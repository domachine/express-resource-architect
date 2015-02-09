_ = require('highland')
mongoose = require('mongoose')
chai = require('chai')
chai.use require('sinon-chai')
sinon = require('sinon')
express = require('express')

Resource = require('../src')

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

describe 'Resource', ->
  describe '#init', ->


    it 'should load all controllers', ->
      controllers = @controllers

      resource = Resource(@app)
      resource 'user', controllers

      @checkInitialization 'user', 'users'

    it 'should load model controllers', ->
      resource = Resource(@app)
      resource @Employee, @controllers

      @app.use.should.have.been.calledOnce

      @checkInitialization 'employee', 'employees'

    it 'should load resource information', (done) ->
      resource = Resource(@app)
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

  describe '#middleware', ->
    before ->
      @Employee = mongoose.model('Employee')
      @employees = [new @Employee(), new @Employee()]
      @employee = Resource.middleware(@Employee, {name: 'emp'})

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

    it 'should create a new middleware bundle', ->
      m = @employee
      for key in m.__middleware
        (typeof m[key]).should.equal 'function'

    describe '#new', ->
      it 'should setup a new object', (done) ->
        @testMiddleware {}, {}, @employee.new(), (err, req, res) =>
          return done(err) if err
          should.exist req.resource
          req.resource.Model.should.equal @Employee
          req.resource.key.should.equal 'employee'
          req.resource.name.should.equal 'emp'
          req.resource.plural.should.equal 'emps'
          req.resource.collectionName.should.equal 'employees'
          res.locals.emp.should.be.instanceof @Employee
          done()

    describe '#create', ->
      it 'should create a new object', (done) ->
        req =
          body:
            name: 'Test name'
            reference: new mongoose.Types.ObjectId()

        @testMiddleware req, {}, @employee.create(), (err, req, res) =>
          return done(err) if err
          res.locals.emp.name.should.equal req.body.name
          done()

      it 'should refuse to create new object with malicious body', (done) ->
        req =
          body:
            name: 'Test name'
            ref: ''

        @testMiddleware req, {}, @employee.create(), (err, req, res) =>
          return done(err) if err
          res.locals.emp.name.should.equal req.body.name
          should.not.exist res.locals.emp.reference
          done()

    describe '#loadAll', ->
      describe 'successCase', ->
        before ->
          sinon.stub @Employee, 'find', (cb) =>
            cb null, @employees

        it 'should load all available objects', (done) ->
          @testMiddleware {}, {}, @employee.loadAll(), (err, req, res) =>
            return done(err) if err
            @Employee.find.should.have.callCount 1
            res.locals.emps.should.equal @employees
            done()

      describe 'failCase', ->
        before ->
          sinon.stub @Employee, 'find', (cb) =>
            cb new Error('Failed!')

        it 'should react appropriately on an error', (done) ->
          @testMiddleware {}, {}, @employee.loadAll(), (err, req, res) =>
            @Employee.find.should.have.callCount 1
            should.exist err
            err.message.should.equal 'Failed!'
            done()

      afterEach ->
        @Employee.find.restore()

    describe '#update', ->
      it 'should pass along because of missing object', (done) ->
        @testMiddleware {}, {}, @employee.update(), (err, req, res) =>
          return done(err) if err
          should.not.exist res.locals.employee
          done()

    describe '#load', ->
      describe 'successCase', ->
        before ->
          sinon.stub @Employee, 'findById', (id, cb) =>
            cb null, new @Employee(name: 'Test')

        it 'should load the object', (done) ->
          req =
            params: employee: 'testId'
          @testMiddleware req, {}, @employee.load(), (err, req, res) =>
            return done(err) if err
            @Employee.findById.should.have.been.calledOnce
            @Employee.findById.args[0][0].should.equal 'testId'
            res.locals.emp.should.be.instanceof @Employee
            done()

        after ->
          @Employee.findById.restore()

      describe 'failCase', ->
        before ->
          sinon.stub(@Employee, 'findById').yields new Error('Failed!')

        it 'should throw the error', (done) ->
          @testMiddleware params: {}, {}, @employee.load(), (err, req, res) =>
            should.exist err
            err.message.should.equal 'Failed!'
            done()

        after ->
          @Employee.findById.restore()

      describe 'notFoundCase', ->
        before ->
          sinon.stub(@Employee, 'findById').yields()

        it 'should pass along because of missing object', (done) ->
          @testMiddleware params: {}, {}, @employee.load(), (err, req, res) =>
            return done(err) if err
            should.not.exist res.locals.employee
            done()

        after ->
          @Employee.findById.restore()

    describe '#save', ->
      describe 'successCase', ->
        before ->
          @e = new @Employee()
          sinon.stub(@e, 'save').yields null, @e

        it 'should save the object', (done) ->
          res = locals: emp: @e
          @testMiddleware {}, res, @employee.save(), (err, req, res) =>
            return done(err) if err
            @e.save.should.have.been.calledOnce
            res.locals.emp.isModified().should.be.false
            res.locals.emp.should.equal @e
            should.not.exist res.locals.emp.errors
            done()

        after ->
          @e.save.restore()

      describe 'validationFailCase', ->
        before ->
          @e = new @Employee()
          sinon.stub(@e, 'save').yields new mongoose.Error.ValidationError({})

        it 'should refuse to save the object', (done) ->
          @e.name = 'test'
          res = locals: emp: @e
          @testMiddleware {}, res, @employee.save(), (err, req, res) =>
            return done(err) if err
            res.locals.emp.isModified().should.be.true
            done()

        after ->
          @e.save.restore()

      describe 'failCase', ->
        before ->
          @e = new @Employee()
          sinon.stub(@e, 'save').yields new Error('Failed!')

        it 'should throw the error', (done) ->
          res = locals: emp: @e
          @testMiddleware {}, res, @employee.save(), (err, req, res) =>
            should.exist err
            err.message.should.equal 'Failed!'
            done()

        after ->
          @e.save.restore()

      describe 'notFoundCase', ->
        before ->
          sinon.stub(@Employee, 'findById').yields()

        it 'should pass along', (done) ->
          @testMiddleware {}, {}, @employee.save(), (err, req, res) =>
            return done(err) if err
            should.not.exist res.locals.employee
            done()

        after ->
          @Employee.findById.restore()
