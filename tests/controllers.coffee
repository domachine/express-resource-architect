mongoose = require('mongoose')
chai = require('chai')
chai.use require('sinon-chai')
sinon = require('sinon')

architect = require('../src')

describe 'Resource', ->
  describe '#controllers', ->
    before ->
      @employees = [new @Employee(), new @Employee()]
      @employee = architect.controllers(@Employee)

    describe '#new', ->
      it 'should setup a new object', (done) ->
        req = {}
        res =
          render: (view) =>
            view.should.equal "#{req.resource.collectionName}/edit"
            should.exist req.resource
            req.resource.Model.should.equal @Employee
            req.resource.key.should.equal 'employee'
            req.resource.name.should.equal 'employee'
            req.resource.plural.should.equal 'employees'
            req.resource.collectionName.should.equal 'employees'
            res.locals.employee.should.be.instanceof @Employee
            done()

        @testMiddleware req, res, @employee.new(), done
