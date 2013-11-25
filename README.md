# Kiosk

Kiosk provides APIs for integrating WordPress content into a Rails
application: a base REST model for retrieving content, a caching layer,
and a rewriting engine for canonicalizing and contextualizing content
elements.

This gem was initially developed by [National Novel Writing
Month](http://nanowrimo.org) for use in its event website. It has since been
released under the MIT license.

## Installation

    gem install kiosk

## Configuration

CMS integration requires a WordPress installation that includes the [JSON
API Plugin](http://wordpress.org/extend/plugins/json-api/).

Once the WP site is up and running, the site endpoint should be specified as
the `origin` content server in `config/kiosk.yml` of your Rails application.
Different configurations may be specified for each Rails environment, along
with a default.

    origins:
      default:
        site: 'http://dev.cms.example/site_name'
      production:
        site: 'http://cms.example/site_name'

Localization of content resources depends further on the installation of the
[WPML Multilingual CMS](http://wpml.org/) (non-free) and [WPML JSON
API](http://wordpress.org/extend/plugins/wpml-json-api/) plugins.

## Simple Example Usage

Looking to serve up content on your Rails site at URLs like
`/pages/example-page`? The process is just as simple as with any other type of
ActiveRecord, Mongoid or other model.

Define a model class to represent any of your WordPress pages

    class Page < Kiosk::WordPress::Page
    end

Set up a route to your pages at `/pages/{id}` and allow the id to work with
WordPress page hierarchies (e.g. `/pages/parent-page/child-page`).

    Example::Application.routes.draw do
      resources :pages, only: [:show], constraints: { id: /.+/ }
    end

Define a controller that retrieves a given page.

    class PagesController < ApplicationController
      def show
        @page = Page.find_by_slug(params[:id])

        # authorization, etc.
      end
    end

Define a view that renders the page content. (Note that in this example we're
trusting the CMS authors to not inject malicious content. You could easily
pass the content through some sort of sanitizer if necessary.)

    <h1><%= @page.title.html_safe %></h1>
    <%= @page.content.html_safe %>

At this point, a request to your Rails application at `/pages/example-page`
will display your WordPress page! But what about all of those links pointing
back to your CMS in the body of the page? There's one final step you have to
take to that will integrate your own routes into the page content:
canonicalization.

Canonicalize your page content by defining a Kiosk rewrite in your controller.
You could do this in the pages controller itself, but if you plan on
exposing CMS resources anywhere else it's usually best to define rewrites in
the application controller.

    class ApplicationController
      include Kiosk::Controller

      before_filter do
        Kiosk.rewriter.reset!
        rewrite_paths_for(Page) { |page| page_path(page) }
      end
    end

That's it! Links in your page content should now point to your Rails page
route and, barring images and other attachments, your CMS pages are fully
embedded in your application. Now put those content editors to work!

## How Canonicalization Works

One of the biggest challenges when implementing Kiosk was writing a
canonicalization system that adheres to Rails MVC. This might sound strange
until you consider some of the constraints that MVC imposes and the nature of
our model data.

First, our content models are essentially ActiveResource classes that
represent WordPress posts, both the metadata _and the post body_, the latter
of which we want to re-frame such that it appears to live at the location of
our Rails application, not WordPress.

Second, MVC constrains the model to know nothing about the context in which it
may be requested or rendered. That knowledge is for the controller and view,
respectively. In other words, to let our content models rewrite links and
other elements within the post with our Rails application routes would have
broken the MVC rules.

In order to play nice with the MVC constraint, Kiosk's canonicalization system
works by a system of "claims" and rewrites of the HTML served up by WordPress.
The model defines the claim, the controller the rewrite.

 1. Content models claim to own certain DOM elements in the HTML of any
    WordPress resource. For example, a `Page` model could claim to own
    all `<a>` elements with hrefs that match the WordPress URL for pages.

 2. Controllers define certain rewrite rules that transform DOM elements
    claimed by a given model. For example, a controller could transform the
    hrefs of the `<a>` elements claimed by `Page` to point to the
    application's `/pages/` route, the latter of which the controller has
    full knowledge of.

In fact, the above is exactly what we did in our example. If you were to look
at the implementation of `Kiosk::WordPress::Page`, you would see something
similar to the following.

    claims_path_content(selector: 'a', pattern: '/[^\?]+/')

For details on how to define more advanced claims, see `Kiosk::Prospector`.

## Roadmap

 - Refactor off of ActiveResource to a lighter weight RESTful client
 - Implement framework-agnostic caching adapter
 - Generalize WordPress integration to pave the way for supporting other CMSs
 - Factor WordPress specifics out to a separate adapter
 - More test coverage!

## Contributions

Kiosk was developed in a pretty isolated environment for the use cases of
National Novel Writing Month. For an open-source project to thrive, it needs
contributors. So please, if you find this gem at all useful, please
contribute!

 - Fork the project and create a topic branch
 - Write tests for your new feature or a test that reproduces a bug
 - Implement your feature or make a bug fix
 - Commit, push and make a pull request

## License

Kiosk is licensed under the terms of the MIT License. See `MIT-LICENSE` for
details.

## Copyright

Copyright (c) 2013 National Novel Writing Month
