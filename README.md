# ExBlog

This is a blogging web application built with Elixir that uses Dynamo to serve web requests. It is an attempt to clone a previous blog application I wrote with Ruby (https://github.com/sausheong/easyblog). In that blog application, I wrote the whole application in 300+ lines of Ruby code. After learning a bit about Elixir and Dynamo, I decided to try to reproduce the same features, but with Elixir and Dynamo.

In short these are the features of ExBlog:

* Create a blog post
* Comment on a blog post
* Markdown display for posts and comment
* Edit and delete posts and comments
* Authentication with Facebook
* Authentication required for posting and commenting
* Need to be the same user to edit and delete posts and comments

These are the technologies I used and works on:

* Elixir 0.10.1 (Erlang E16B)
* Dynamo 0.1.0-dev (with built-in EEx)
* Mnesia

For the web technologies I use Bootstrap 2.3.2 and Font Awesome 3.2.1 directly from BootstrapCDN, with the Flatly theme.

Note that this writeup does NOT explain how this web application is developed.


## How to deploy ExBlog

You need to do a few things manually to deploy and run this app:

### Get all dependencies

Do this first to get download all the dependencies.

```
mix deps.get
```

Note that all the dependencies will get downloaded into a directory named `deps`.

### Add the delete_session function into Dynamo

As of `0.10.1` Dynamo doesn't have the API to remove something from the session, even though you can put stuff in it. I've added this features as a pull request in Dynamo (https://github.com/elixir-lang/dynamo/pull/115). As soon as José merges that pull request you don't need to do this any more, but for now, this is what you need to do:

1. Go to `<your exblog directory>/deps/dynamo/lib/dynamo/http/session.ex`
2. Add in this anywhere in the code:

```elixir
@doc """
Removes the session for the given key
"""
def delete_session(conn, key) do    
  private = conn.private
  session = List.keydelete(get_session(conn), key, 0)
  mark_as_writen conn.put_private(@session, session), private
end
```

3. Because we have made changes to one of the dependencies, we need to re-compile all the dependencies (at least the ones we changed) by running this in the console.

```
mix deps.compile
```

### Create a Facebook app and get the app ID and the app secret

I used Facebook to perform all authentication. So to deploy ExBlog properly you need to have a Facebook app. Go to https://developers.facebook.com/apps and create a new app. Fill up what you need and in the end you'll be provided an app ID and an app secret. Remember to also configure how the app integrates with Facebook (in the settings tab).

Select such that you integrate as a "Website with Facebook Login". For testing purposes on your development computer, set the Site URL to `http://localhost:4000/` but if you ever need to deploy it beyond your computer, you'll need to change this.

With the app ID and app secret go to `<your exblog directory>/lib/exblog/environments/dev.exs`. This is the settings for your development environment. If you're setting up for test or production, open up `test.exs` or `prod.exs` accordingly. You should see a section at the bottom of the page like this:
  
```elixir
config :facebook,
  app_id: "",
  secret: "",
  callback_url: "http://localhost:4000/auth/callback"
```
  
Replace the app ID and app secret accordingly. Note that if you ever set up beyond localhost you will need to change the callback URL as well.

### Start up ExBlog

Now you're ready to start up ExBlog. Run this on your console.

```
mix do compile, server
```

~~There'll be some warnings. Ignore them. I haven't figured out what's the best way to make it work without the warnings yet but they're harmless.~~ José explained to me that it's because of the way I grouped my functions. Duh.

The go to `http://localhost:4000` on your browser. The first time you run it there'll be some exceptions. Ignore them and refresh the page. Again this is because I haven't figured out how to set up Mnesia properly the first time. The exceptions are there because Mnesia is complaining they can't find the files, which actually gets generated right afterwards. 

And there you have it!

## How does it all work?

I'm working on a step-by-step tutorial to explain how all this works. 

## What about tests?

My bad. My lame excuse is that I'm busy learning Elixir and Dynamo. Coming soon!


## What else?

I'm still learning Elixir so this is probably not what you're looking for if you're looking for some experienced Elixir programmer to copy from (I'm probably doing all sorts of things wrongly). But if you're looking at someone who has walked through the web application development path with Elixir and Dynamo and came out with an actual working application, this is it.

When I tried my hand at it I didn't know about Ecto, and so I did everything with Mnesia (I didn't really relish directly accessing Postgres) as the storage backend. Now that I know about Ecto, that'll be what I'll be trying next.


## Resources

* [Elixir website](http://elixir-lang.org/)
* [Elixir getting started guide](http://elixir-lang.org/getting_started/1.html)
* [Elixir docs](http://elixir-lang.org/docs)
* [Dynamo source code](https://github.com/elixir-lang/dynamo)
* [Dynamo guides](https://github.com/elixir-lang/dynamo#learn-more)
* [Dynamo docs](http://elixir-lang.org/docs/dynamo)
