###!
App.net timeline fetcher (c) 2013 Brandon Mathis, @imathis // MIT License
###


AdnTimeline =
  defaults:
    el: '.adn-timeline'
    count: 4
    replies: false
    reposts: false
    cookie: 'adn-timeline'

  # A page can render multiple timelines
  # Options can be passed as simple hash, but an array allows multiple timelines to be configured independantly
  # If no options are passed init will look for elements with the class '.adn-feed' and read data attributes to configure options
  init: (optionsArray=[{}]) ->
    
    # Single options hashes are dropped into an array to unify the approach
    optionsArray = [optionsArray] unless optionsArray instanceof Array
    for options in optionsArray

      # Configuring timeline is very flexible
      # Options are loaded in order of element data-attributes, passed options, and finally defaults.
      $(options.el or @defaults.el).each (i, el) =>
        el = $(el)
        user =  @cascadeOptions el.attr('data-username'), options.username
        return console.error 'You need to provide an App.net username' unless user?
        renderer = options.render or @render
        callback = options.callback or (->)
        @timeline(@helpers).fetch renderer, callback,
          el:      el
          user:    user
          count:   @cascadeOptions parseInt(el.attr('data-count')),     options.count,   @defaults.count
          replies: @cascadeOptions @parseBool(el.attr('data-replies')), options.replies, @defaults.replies
          reposts: @cascadeOptions @parseBool(el.attr('data-reposts')), options.reposts, @defaults.reposts
          cookie:  @cascadeOptions @parseBool(el.attr('data-cookie')),  options.cookie,  "#{@defaults.cookie}-#{user}" 
    @

  # Walk through a series of options, returning the first option which is not undefined or NaN.
  # This allows options to cascade.
  cascadeOptions: (options...) ->
    for option in options
      if option? and option is option
        return option; break

  # Convert strings like "true" and " false " to proper Booleans.
  parseBool: (str)->
    if str?
      str = str.trim()
      return true if str.match /^true$/i
      return false if str.match /^false/i
      return console.error "\"#{str}\" cannot be parsed as Boolean"

  # Convert posts to HTML and render them in target element.
  render: (el, posts) ->
    text  = "<ul id='adn-timeline-imathis'>"
    for post in posts
      text += "<li><figure class='post'>"
      text += "<blockquote><p>"
      text += post.text
      text += "</p></blockquote>"
      text += "<figcaption>"
      text += "<a href='#{post.url}' class='adn-post-url'><time datetime='#{post.date}'>#{post.display_date}</time></a>"
      text += "</figcaption>"
      text += "</figure></li>"
    text += "</ul>"
    el.append text

  # Returns a function for easy variable scoping
  timeline: (helpers) ->
    data: []

    # Lets get some data!
    fetch: (renderer, callback, options) ->
      
      # Using the jquery cookies plugin is optional, but recommended
      # When testing we can set cookie to false to disable cookie storage
      if $.cookie and options.cookie and posts = $.cookie options.cookie
        data = JSON.parse posts
        if data.length isnt options.count
          $.removeCookie options.cookie
          @fetch renderer, callback, options
        else 
          renderer options.el, data
          callback data
      else
        url =  "https://alpha-api.app.net/stream/0/users/@#{options.user}/posts?include_deleted=0"
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
              @fetch renderer, callback, options

            else 
              # Now that we have enough posts, let's condense the data and store a cookie if possible.
              @data = (helpers.postData post for post in @data.slice(0, options.count))
              $.cookie(options.cookie, JSON.stringify @data, { path: '/' }) if $.cookie and options.cookie

              renderer options.el, @data
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
      text = text.replace new RegExp("@(#{mention.name})", "gi"), "<a href='https://alpha.app.net/$1'>@$1</a>" for mention in post.entities.mentions
      text = text.replace "##{hashtag.name}", "<a href='https://alpha.app.net/hashtags/#{hashtag.name}'>##{hashtag.name}</a>" for hashtag in post.entities.hashtags
      text

    postData: (post) ->
      {
        url: post.canonical_url
        date: post.created_at
        display_date: @timeago post.created_at
        author: { username: post.user.username, name: post.user.name, url: post.user.canonical_url }
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
