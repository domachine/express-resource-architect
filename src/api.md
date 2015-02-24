# Api

## architect(app)

This constructs a new architect instance which wraps the express
application `app`.  The instance is a `function` described below.

*e.g.*

<script src="https://gist.github.com/domachine/4f425a871cfa62616ad6.js"></script>

## instance(model|name, [plural], controllers)

Instantiates a new resource on the architect and registers the
corresponding routes.

*Arguments*

 * `model|name` - This can be either a mongoose model or a simple
   resource name like *user*.

 * `plural` - Per default `the architect` will construct the plural by appending
   a *s* to the name.  If the resource plural is different you can
   pass it using this argument.

 * `controllers` - This is the map of controllers
   * `list`
   * `new`
   * `show`
   * `edit`
   * `create`
   * `update`
   * `partialUpdate`
   * `destroy`

 each value must be a valid
 [express route handler](http://expressjs.com/4x/api.html#app.METHOD).

## architect.middleware()

*docs coming soon*

## architect.controllers()

*docs coming soon*
