###!
App.net timeline fetcher (c) 2013 Brandon Mathis, @imathis // MIT License
Version: 1.2
Source: https://github.com/imathis/adn-timeline/
###


class AdnTimeline
  defaults:
    el: '.adn-timeline'
    count: 4
    replies: false
    reposts: false
    cookie: 'adn-timeline'
    avatars: false

  # A page can render multiple timelines
  # Options can be passed as simple hash, but an array allows multiple timelines to be configured independantly
  # If no options are passed init will look for elements with the class '.adn-feed' and read data attributes to configure options
  constructor: (optionsArray=[{}]) ->
    
    # Single options hashes are dropped into an array to unify the approach
    optionsArray = [optionsArray] unless optionsArray instanceof Array
    for options in optionsArray

      # Configuring timeline is very flexible
      # Options are loaded in order of element data-attributes, passed options, and finally defaults.
      $(options.el or @defaults.el).each (i, el) =>
        el = $(el)
        options.render or= @render
        callback = options.callback or (->)
        options = $.extend({}, @defaults, options, el.data())
        options.el = el
        options.username = options.username?.replace '@', ''
        options.hashtag = options.hashtag?.replace '#', ''
        return console.error 'You need to provide an App.net username or hashtag' unless options.username? or options.hashtag?
        options.cookie = options.cookie + "-#{options.username or options.hashtag}" if options.cookie is @defaults.cookie

        @timeline(@helpers).fetch @render, callback, options
    @

  # Walk through a series of options, returning the first option which is not undefined or NaN.
  # This allows options to cascade.
  cascadeOptions: (options...) ->
    for option in options
      if option? and option is option
        return option; break

  # Convert posts to HTML and render them in target element.
  render: (options, posts) ->
    el = options.el
    text  = "<ul id='adn-timeline-#{options.username or options.hashtag}'>"
    for post in posts
      text += "<li><figure class='adn-post'>"
      if post.author.avatar
        text += "<a href='#{post.author.url}' class='adn-author-avatar-link'>"
        text += "<img alt='@#{post.author.username}'s avatar on App.net' class='adn-author-avatar' width=48 src='#{post.author.avatar}'>"
        text += "</a>"
      text += "<figcaption>"
      if post.author.unique
        text += "<p>"
        text += "<a href='#{post.author.url}' class='adn-author-url' rel=author>"
        text += "<strong class='adn-author-name'>#{post.author.name}</strong> <span class='adn-author-username'>@#{post.author.username}</span>"
        text += "</a></p>"
      text += "<a href='#{post.url}' class='adn-post-url'><time datetime='#{post.date}'>#{post.display_date}</time></a>"
      text += "</figcaption>"
      text += "<blockquote><p>"
      text += post.text
      text += "</p></blockquote>"
      text += "<p class='adn-reposted'><span class='adn-repost-marker'>➥</span> reposted by <a href='#{post.repost.user.url}'>#{post.repost.user.name}</a></p>" if post.repost
      text += "</figure></li>"
    text += "</ul>"
    el.append text

  # Returns a function for easy variable scoping
  timeline: (helpers) ->
    data: []

    # Let's get some data!
    fetch: (render, callback, options) ->
      
      # Using the jquery cookies plugin is optional, but recommended
      # When testing we can set cookie to false to disable cookie storage
      if $.cookie and options.cookie and posts = $.cookie options.cookie
        data = JSON.parse posts
        if data.length isnt options.count
          $.removeCookie options.cookie
          @fetch render, callback, options
        else 
          options.render options, data, render
          callback data
      else
        url =  "https://alpha-api.app.net/stream/0/"
        url += "users/@#{options.username}/posts?include_deleted=0" if options.username
        url += "posts/tag/#{options.hashtag}?include_deleted=0" if options.hashtag
        # before_id allows us to page through posts if the first fetch didn't yeild enough posts.
        url += "&before_id=#{options.before_id}" if options.before_id
        url += "&include_directed_posts=0" unless options.replies
        url += "&callback=?"

        $.ajax
          url:      url
          dataType: 'jsonp'
          error:    (err)  ->
            console.error 'Error fetching App.net timeline'
            console.error err
          success:  (response) => 

            # Strip out reposts if necessary 
            unless options.reposts
              data = []
              (data.push post unless post.repost_of) for post in response.data
              response.data = data

            # Add up response data to see if we have enough posts to continue
            @data = @data.concat response.data
            if @data.length < options.count

              # Set before_id and fetch the next page of posts
              options.before_id = response.meta.min_id
              @fetch render, callback, options

            else 
              # Now that we have enough posts, let's condense the data and store a cookie if possible.
              @data = (helpers.postData post, options for post in @data.slice(0, options.count))
              $.cookie(options.cookie, JSON.stringify @data, { path: '/' }) if $.cookie and options.cookie

              options.render options, @data, render
              callback @data
  
  # Post parsing helpers are scoped for easier internal referencing when passed into timeline
  helpers:

    # Trims urls to 40 characters. Tries to trim urls elegantly on a '/'.
    # Why 40 characters? When linking to App.net posts, usernames (which can be 20 characters) are never trimmed.
    trimUrl: (url)->
      parts = []
      max = 40
      url = url.replace /(https?:\/\/)/i, ''

      # Split up a url then put it back together until it's too long
      for part in url.split '/'
        break unless parts.concat(part).join('/').length < max
        parts.push part
      short = parts.join('/')

      # If a url gets too short, slice at 40 characters to preserve useful url information.
      # http://example.com/?q=wow+that+is+quite+a+query+you+have+there would be trimmed to example.com...
      # Instead we get example.com/?q=wow+that+is+quite+a+query...
      short = url.slice(0, max) if url.length - short.length > 15

      # Finally add an elipsis if the url was actually shortened
      if short.length < url.length then short + '&hellip;' else short

    # Replace the display urls with shorter ones preventing long urls from dominating a post
    trimDisplayUrls: (text)->
      text.replace />\s*(https?:\/\/.+?)\s*</gi, (match, p1)=> ">#{@trimUrl(p1)}<"

    # Trim urls and replace mentions and hashtags with links
    linkify: (post)->
      text = @trimDisplayUrls post.html

      # Using entities from the API ensures we never accidentally link a username with no account.
      # We could use a regex for hastags but this format is more clear and there's no worry that our regex differs from App.net.
      text = text.replace new RegExp("@(#{mention.name})", "gi"), "<a class='adn-username' href='https://alpha.app.net/$1'>@$1</a>" for mention in post.entities.mentions
      text = text.replace new RegExp("#(#{hashtag.name})", "gi"), "<a class='adn-hashtag' href='https://alpha.app.net/hashtags/$1'>#$1</a>" for hashtag in post.entities.hashtags
      text

    postData: (post, options) ->
      repost = if !!(post.repost_of) then { user: { username: post.user.username, name: post.user.name, ur: post.user.canonical_url } } else false
      post = post.repost_of if repost
      avatar = post.user.avatar_image.url if options.avatars
      {
        repost: repost
        url: post.canonical_url
        date: post.created_at
        display_date: @timeago post.created_at
        author: { username: post.user.username, name: post.user.name, url: post.user.canonical_url, avatar: avatar, unique: !!(options.reposts or options.hashtag) }
        text: @linkify post
      }

    # Timeago by Brandon Mathis, based on JavaScript Pretty Date Copyright (c) 2011 John Resig
    # Returns relative time
    timeago: (time)->
      say =
        just_now:    "now"
        minute_ago:  "1m"
        minutes_ago: "m"
        hour_ago:    "1h"
        hours_ago:   "h"
        yesterday:   "1d"
        days_ago:    "d"
        last_week:   "1w"
        weeks_ago:   "w"

      secs  = ((new Date().getTime() - new Date(time).getTime()) / 1000)
      mins  = Math.floor secs / 60
      hours = Math.floor secs / 3600
      days  = Math.floor secs / 86400
      weeks = Math.floor days / 7

      return '#' if isNaN(secs) or days < 0

      if days is 0
        if      secs < 60   then say.just_now
        else if secs < 120  then say.minute_ago 
        else if secs < 3600 then mins + say.minutes_ago 
        else if secs < 7200 then say.hour_ago
        else                     hours + say.hours_ago
      else
        if days is 1        then say.yesterday
        else if days < 7    then days + say.days_ago
        else if days is 7   then say.last_week
        else                     weeks + say.weeks_ago
      
# CommonJS Footer
if exports? 
  if module? and module.exports
    exports = module.exports = AdnTimeline
  else
    exports.AdnTimeline = AdnTimeline
else
  @AdnTimeline = AdnTimeline
