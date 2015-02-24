# express-resource-architect
## *Kickstart applications with resources*

[![Build Status](https://travis-ci.org/domachine/express-resource-architect.svg?branch=master)](https://travis-ci.org/domachine/express-resource-architect)

*This currently is in heavy development*.  It might quickly
 change. You should probably not use it before *1.0.0*.

## Idea

As we're developing many applications in a restful manner with express
and mongoose, I saw a lot of code being duplicated over and over
again.  We've got many use-cases where a resource should be manageable
using a nice interface.  In 80 percent of all cases, this consists of
the typical MVC views:

* `new`
* `create`
* `edit`
* `update`

We solve this by splitting such a resource in 2 parts.  One is the
route registration, the second is the controller which is
representated using the route-handler an express app receives.

**Example:**

*Route registration*

```coffee
express = require('express')

controllers = require('./controllers/users')

app = express()

app.get '/users/new', controllers.new
```

*Controller (controllers/users.coffee)*

```coffee
mongoose = require('mongoose')

User = mongoose.model('User')

exports.new = (req, res, done) ->
  user = new User()
  res.render 'users/new', user: user
```

Controllers of those simple cases are needed over and over again.
This is really error-prone and could be abstracted I think so I
started this tiny module.

The first abstraction is the idea that controllers should have simple
default routes based on their name.  So using this module we could
write the above example like the following:

```coffee
architect = require('express-resource-architect')
mongoose = require('mongoose')

resource = architect(app)

resource mongoose.model('User'), require('./controllers/users')
```

The controller is then as easy as this:

```coffee
architect = require('express-resource-architect')

c = architect.controllers()

exports.new = c.new()
```

This is a really leaky abstraction you may say, but for cases where
you need more control we also got some awesomeness: *middleware*.
These are tinier pieces of a controller (in fact every controller
consists of middleware) which can be used independly.  This does the
same as the above example:

```coffee
architect = require('express-resource-architect')

m = architect.middleware()

exports.new = [
  m.new()
  m.view 'users/new', true
]
```

I'm currently working hard to shape the API and stabilize this thing.
Currently it's an idea that follows frameworks like sails or ruby on
rails but without the bloat and the loss of flexibility since it
always remains express.
