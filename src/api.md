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

## architect.middleware([model], [opts])

Instantiates a new middleware bundle for the specified arguments.  If no model
or opts are given, they are derived from the router.

*Options*
 * `name` - Specify the resource name if no model is available.
 * `plural` - Specify the resource plural if no model is available.
 * `key` - The param-name to read the id from the url.
 * `collectionName` - The collection-name to use if no model is available.

### Available middleware

#### .load()

Load the object using the id read from the url params.

#### .loadAll()

Load all available objects and populate them under the resource plural.

#### .update()

Update the loaded object.

#### .save()

Save the loaded object.

#### .redirectOnSuccess(url)

Redirect after a successful save operation.

#### .destroy()

Remove the loaded object from the database.

#### .redirect(url)

Redirect to `url`.

#### .view(name)

Render the specified view.

## architect.controllers([model], [opts])

This takes the exact same arguments as `.middleware()`.

It returns an object with controllers for each resource action.
