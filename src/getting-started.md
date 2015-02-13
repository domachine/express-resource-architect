## Installation

    $ npm install --save express-resource-architect

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

<script src="https://gist.github.com/domachine/ef60a40361584a1422fd.js"></script>

*Controller (controllers/users.coffee)*

<script src="https://gist.github.com/domachine/d16e213d4b74162238d7.js"></script>

Controllers of those simple cases are needed over and over again.
This is really error-prone and could be abstracted I think so I
started this tiny module.

The first abstraction is the idea that controllers should have simple
default routes based on their name.  So using this module we could
write the above example like the following:

<script src="https://gist.github.com/domachine/491eebc30373675898f5.js"></script>

The controller is then as easy as this:

<script src="https://gist.github.com/domachine/2505e7fa9df5ec8b413b.js"></script>

This is a really leaky abstraction you may say, but for cases where
you need more control we also got some awesomeness: *middleware*.
These are tinier pieces of a controller (in fact every controller
consists of middleware) which can be used independly.  This does the
same as the above example:

<script src="https://gist.github.com/domachine/7eef4bc67b3af5b6f560.js"></script>

I'm currently working hard to shape the API and stabilize this thing.
Currently it's an idea that follows frameworks like sails or ruby on
rails but without the bloat and the loss of flexibility since it
always remains express.
