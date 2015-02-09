mongoose = require('mongoose')
chai = require('chai')
chai.use require('sinon-chai')
sinon = require('sinon')

architect = require('../src')

should = chai.should()

describe 'controllers', ->
  before ->
    @employees = [new @Employee(), new @Employee()]
    @employee = architect.controllers(@Employee, name: 'emp')

  describe '#list', ->
    before ->
      sinon.stub(@Employee, 'find').yields null, @employees

    it 'should list all objects of a given model', (done) ->
      req = {}
      res =
        render: (view) =>
          should.exist req.resource
          should.exist res.locals.emps
          res.locals.emps.should.equal @employees
          view.should.equal "#{req.resource.collectionName}/list"
          done()

      @testMiddleware req, res, @employee.list(), done

    after ->
      @Employee.find.restore()

  describe '#new', ->
    it 'should setup a new object', (done) ->
      req = {}
      res =
        render: (view) =>
          view.should.equal "#{req.resource.collectionName}/edit"
          should.exist req.resource
          req.resource.Model.should.equal @Employee
          req.resource.key.should.equal 'employee'
          req.resource.name.should.equal 'emp'
          req.resource.plural.should.equal 'emps'
          req.resource.collectionName.should.equal 'employees'
          res.locals.emp.should.be.instanceof @Employee
          done()

      @testMiddleware req, res, @employee.new(), done

  describe '#edit', ->
    describe 'successCase', ->
      before ->
        sinon.stub(@Employee, 'findById').yields(
          null, new @Employee(name: 'Test 1')
        )

      it 'should fetch an object and edit it', (done) ->
        req = params: employee: '123'
        res =
          render: (view) =>
            view.should.equal "#{req.resource.collectionName}/edit"
            should.exist req.resource
            res.locals.emp.should.be.instanceof @Employee
            done()

        @testMiddleware req, res, @employee.edit(), done

      after ->
        @Employee.findById.restore()

    describe 'notFoundCase', ->
      before ->
        sinon.stub(@Employee, 'findById').yields()

      it 'should not fetch the given model', (done) ->
        req = params: employee: '123'
        res =
          render: sinon.spy()

        @testMiddleware req, res, @employee.edit(), (err) =>
          return done(err) if err
          should.exist req.resource
          (!!res.locals.emp).should.be.false
          res.render.should.not.have.been.called
          done()

      after ->
        @Employee.findById.restore()

  describe '#update', ->
    describe 'successCase', ->
      before ->
        sinon.stub(@Employee, 'findById').yields(
          null, new @Employee(name: 'Test 1')
        )

      it 'should update the given model', (done) ->
        req =
          params: employee: '123'
          body: name: 'Test 2'
        res =
          render: (view) =>
            should.exist req.resource
            should.exist res.locals.emp
            res.locals.emp.name.should.equal 'Test 2'
            view.should.equal "#{req.resource.collectionName}/edit"
            @Employee.findById.should.have.been.calledOnce
            @Employee.findById.args[0][0].should.equal '123'
            done()

        @testMiddleware req, res, @employee.update(), done

      after ->
        @Employee.findById.restore()

    describe 'notFoundCase', ->
      before ->
        sinon.stub(@Employee, 'findById').yields()

      it 'should update the given model', (done) ->
        req =
          params: employee: '123'
          body: name: 'Test 2'
        res =
          render: sinon.spy()

        @testMiddleware req, res, @employee.update(), (err) =>
          return done(err) if err
          should.exist req.resource
          (!!res.locals.emp).should.be.false
          res.render.should.not.have.been.called
          done()

      after ->
        @Employee.findById.restore()
