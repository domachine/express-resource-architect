mongoose = require('mongoose')
chai = require('chai')
chai.use require('sinon-chai')
sinon = require('sinon')

architect = require('../src')

should = chai.should()

describe 'middleware', ->
  before ->
    @employees = [new @Employee(), new @Employee()]
    @employee = architect.middleware(@Employee, {name: 'emp'})

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
        should.not.exist res.locals.emp
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
          should.not.exist res.locals.emp
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
          should.not.exist res.locals.emp
          done()

      after ->
        @Employee.findById.restore()
