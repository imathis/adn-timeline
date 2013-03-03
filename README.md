## App.net Timeline

Display recent posts for one or more App.net user accounts or hashtags. 

[View the demo](http://imathis.github.com/adn-timeline)

Get it: [JS](https://github.com/imathis/adn-timeline/blob/master/javascripts/) and [SCSS](https://github.com/imathis/adn-timeline/blob/master/stylesheets/sass/adn-timeline.scss) or [CSS](https://github.com/imathis/adn-timeline/blob/master/stylesheets/adn-timeline.css).

The [coffeescript](https://github.com/imathis/adn-timeline/blob/master/javascripts/coffeescript/adn-timeline.coffee) source is pretty well documented if you're curious.

## Dependencies

1. jQuery (for ajax and dom manipulation)
2. jQuery.cookie (optional but recommended)

Note: I generally dislike expecting people to use jQuery for such a simple plugin, but chances are, you're already using it. If enough people are interested, I can write a
standalone version with jXHR or something.

## Basic usage

First include the necessary scripts.

```
<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script type="text/javascript" src="/javascripts/lib/jquery.cookie.min.js"></script>
<script type="text/javascript" src="/javascripts/adn-timeline.js"></script>
```

*Note: jQuery Cookie is optional.*

Next, initialize your ADN timeline.

```
$(document).ready(function(){
  AdnTimeline.init()
})
```

Finally, somehwere on your page, add a block-level element (probably a `div` or a `section`) with a class `adn-timeline` and add your username a `data-username` attribute.

```
<div class='adn-timeline' data-username='imathis'></div>
```

To add a timeline for a hashtag do this.

```
<div class='adn-timeline' data-hashtag='adn'></div>
```

#### Want more than one account?

If you want to have more than one feed on your page, just add another div with a different username.

```
<div class='adn-timeline' data-username='imathis'></div>
<div class='adn-timeline' data-username='octopress'></div>
```

Note: Data is appended to the target elements so we can have content in these elements without worring that it will be overwritten. It would make sense to do something
like this.

```
<div class='adn-timeline' data-user='imathis'>
  <h4>@imathis on App.net</h4>
</div>
```

The heading will remain and posts will be added below in a `<ul>`.

#### Styling

If you're using Sass, grab the [scss](https://github.com/imathis/adn-timeline/blob/master/stylesheets/sass/adn-timeline.scss), import it and include its styles.

```scss
@import 'adn-timeline';

// Include the layout and theme mixins
.adn-timeline {
  @include adn-timeline-layout;
  @include adn-timeline-theme;
}
``

Otherwise you can just use [vanilla CSS](https://github.com/imathis/adn-timeline/blob/master/stylesheets/adn-timeline.css).

## Configuration options

ADN Timeline is easy to configure. You can set preferences as HTML5 data attributes or through javascript.

### Defaults

ADN Timeline has defautls for everything other than username or hashtag.

| Config     | Default                 | Description
|:-----------|:------------------------|:----------------------------------------------|
| `el`       | '.adn-timeline'         | A jQuery selector (handles multiple elements) |
| `username` | undefined               | Show posts for a specific App.net username    |
| `hashtag`  | undefined               | Show posts from a hashtag on App.net          |
| `count`    | 4                       | How many posts to show from your timeline     |
| `avatars`  | false                   | Show avatars in post template                 |
| `replies`  | false                   | Include reply posts                           |
| `reposts`  | false                   | Include reposts                               |
| `cookie`   | 'adn-timeline-username' | Choose a different name for the cookie        |
| `callback` | (function(){})          | Provide a callback function                   |
| `render`   | AdnTimeline.render      | Provide a custom html render function         |

Note: Setting `cookie` to false will disable cookie storage. This is especially helpful when testing.

### Configure with data attributes

In the simple example above we configured the username using an HTML5 data attribute. All configurations may be set with data attributes except for `el`, `callback` and `render` which must be set with an options hash.
Here's an example.

```
<div class='.adn-timeline' data-username='imathis' data-count='10' data-replies='true' data-reposts='true' data-cookie='delicious-cookie'></div>
```

### Configure with an options hash

Using an options hash allows us to change the selector and use a custom callback.

```
$(document).ready(function(){
  AdnTimeline.init({
      el:      '.timeline'
    , count:   5
    , replies: true
    , reposts: false
    , avatars: true
    , cookie:  'delicious-cookie'
    , callback: function (data) { console.log(data) }
    , renderer: function (el, data) { /* rendering code here */ }
  })
})
```

### Combine the options hash and the data attributes

Options are loaded in order of the element data attributes, the options hash, and finally the defaults. This means we can combine methods of setting options like this.

```
$(document).ready(function(){
  AdnTimeline.init({
      el:      '.timeline'
    , replies: true
  })
})
```

```
<div class='timeline' data-username='imathis'></div>
<div class='timeline' data-username='octopress' data-reposts='true'></div>
```

Here we have changed the selector used, both accounts will show replies, and the Octopress account will show reposts.

### Configuring with multiple hashes

In the example above we set reposts to true for @Octopress but not for @imathis. If we configured it in the options hash it would have applied to both accounts. It's
probably easier to set that configuration with a data attribute, but AdnTimeline also accepts an array of option hashes. We do the same configuration above like this.

```
$(document).ready(function(){
  AdnTimeline.init([
    {
        el:       '.timeline-imathis'
      , username: 'imathis'
      , replies:  true
    },{
        el:       '.timeline-octopress'
      , username: 'octopress'
      , replies:  true
      , reposts:  true
    }
  ])
})
```

Then the HTML will no longer need `data-username` attributes since the configuration is derived from the options array. Note that the `el` property now must be unique.

```
<div class='timeline-imathis'></div>
<div class='timeline-octopress'></div>
```

An array of options allows us to set different callbacks and rendering functions based on each username. It's generally better to configure timelines with the data
attributes, but in some cases it might be helpful to configure things more dynamically with javascript.

## HTML Rendering

For a user timeline the default render function appends the following HTML template to the target element(s).

```
<ul>
  <li>
    <figure class="post">
      <figcaption>
        <a href='http://alpha.app.net/username/post/id'>
          <time datetime="2013-02-14T05:03:14Z">2h</time>
        </a>
      </figcaption>
      <blockquote>
        <p>Post Text</p>
      </blockquote>
    </figure>
  </li>
  ...
</ul>
```

For a repost inside of a user's timeline, the original author information is included in the `figcaption` like this.

```
<figcaption>
<p>
  <span class="adn-repost-marker">>> </span>
  <a href="https://alpha.app.net/username" class="adn-author-url" rel="author">
    <strong class="adn-author-name">User Name</strong>
    <span class="adn-author-username">@username</span>
  </a>
</p>
<a href='http://alpha.app.net/username/post/id'>
  <time datetime="2013-02-14T05:03:14Z">2h</time>
</a>
</figcaption>
```

When fetching a hashtag timeline, each author's information is included in the `figcaption` like above, but the repost marker `>>` is omitted.

#### Why this HTML?

While this may seem somewhat verbose, I believe it is a semantically appropriate way to display a timeline feed. After all they are a series of quotes with timestamped meta data linking to the source.
If you haven't seen a figure used to group a `blockquote` with metadata, take a look at the [blockquote spec](http://www.whatwg.org/specs/web-apps/current-work/multipage/grouping-content.html#the-blockquote-element) where you'll find an exmaple just like what I've done.

If you have an alternate proposal I'd love to hear it. Currently the strongest argument against this markup is that people often treat blockquotes or figures with global styling not anticipating them to be used
like this. This would mean they would have to change their site designs to be less broad or override some styles to integrate this timeline.

## Using a custom render function

It's fairly easy add a custom render function. The function will receive the options array (including the jQuery wrapped element at options.el) and a array of post data hashes with the following format:

```
author: {
  username:   post.user.username,
  name:       post.user.name,
  url:        post.user.canonical_url
  unique:     false (true if user is a repost or in a hashtag timeline)
  avatar:     post.user.avatar_image.url
}
url:          post.canonical_url
date:         post.created_at
display_date: post.created_at (converted to relative time)
text:         post.html (with trimmed display urls and auto-linked mentions and hashtags)
repost:       true or false based on the post.repost_of
```

### Custom render function

To write a custom render function we can simply pass it as an option in the options hash. Adding a custom render function could be as simple as this.

```
AdnTimeline.init({
  render: (function(options, posts) {
    var html, i, len
    html  = "<ul>"
    for (i = 0, len = posts.length; i < len; i++) {
      html += "<li>"
      html += ("<p>" + posts[i].text + "</p>")
      html += "</li>"
    }
    html += "</ul>"
    options.el.append(html)
  })
})
```

Which would output:

```
<ul>
  <li>
    <p>post text<p>
  </li>
<ul>
```

Note: The current HTML render function doesn't make use of the author data. But I've considered reformating reposts to use this data in a nicer way. Currently reposts use
the `>> @username: ` format.

## License MIT

Copyright 2013, Brandon Mathis.
Released under an [MIT license](http://opensource.org/licenses/MIT).
