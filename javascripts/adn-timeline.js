
/*!
App.net timeline fetcher (c) 2013 Brandon Mathis, @imathis // MIT License
Version: 1.2
Source: https://github.com/imathis/adn-timeline/
*/


(function() {
  var AdnTimeline, exports,
    __slice = [].slice;

  AdnTimeline = {
    defaults: {
      el: '.adn-timeline',
      count: 4,
      replies: false,
      reposts: false,
      cookie: 'adn-timeline',
      avatars: false
    },
    init: function(optionsArray) {
      var options, _i, _len,
        _this = this;
      if (optionsArray == null) {
        optionsArray = [{}];
      }
      if (!(optionsArray instanceof Array)) {
        optionsArray = [optionsArray];
      }
      for (_i = 0, _len = optionsArray.length; _i < _len; _i++) {
        options = optionsArray[_i];
        $(options.el || this.defaults.el).each(function(i, el) {
          var callback, renderer, _ref, _ref1;
          el = $(el);
          renderer = options.render || _this.render;
          callback = options.callback || (function() {});
          options = $.extend({}, _this.defaults, options, el.data());
          options.el = el;
          options.username = (_ref = options.username) != null ? _ref.replace('@', '') : void 0;
          options.hashtag = (_ref1 = options.hashtag) != null ? _ref1.replace('#', '') : void 0;
          if (!((options.username != null) || (options.hashtag != null))) {
            return console.error('You need to provide an App.net username or hashtag');
          }
          if (options.cookie === _this.defaults.cookie) {
            options.cookie = options.cookie + ("-" + (options.username || options.hashtag));
          }
          return _this.timeline(_this.helpers).fetch(renderer, callback, options);
        });
      }
      return this;
    },
    cascadeOptions: function() {
      var option, options, _i, _len;
      options = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = options.length; _i < _len; _i++) {
        option = options[_i];
        if ((option != null) && option === option) {
          return option;
          break;
        }
      }
    },
    render: function(options, posts) {
      var el, post, text, _i, _len;
      el = options.el;
      text = "<ul id='adn-timeline-" + (options.username || options.hashtag) + "'>";
      for (_i = 0, _len = posts.length; _i < _len; _i++) {
        post = posts[_i];
        text += "<li><figure class='adn-post'>";
        if (post.author.avatar) {
          text += "<a href='" + post.author.url + "' class='adn-author-avatar-link'>";
          if (post.author.avatar) {
            text += "<img alt='@" + post.author.username + "'s avatar on App.net' class='adn-author-avatar' width=48 src='" + post.author.avatar + "'>";
          }
          text += "</a>";
        }
        text += "<figcaption>";
        if (post.author.unique) {
          text += "<p>";
          if (post.repost) {
            text += "<span class='adn-repost-marker'>>></span> ";
          }
          text += "<a href='" + post.author.url + "' class='adn-author-url' rel=author>";
          text += "<strong class='adn-author-name'>" + post.author.name + "</strong> <span class='adn-author-username'>@" + post.author.username + "</span>";
          text += "</a></p>";
        }
        text += "<a href='" + post.url + "' class='adn-post-url'><time datetime='" + post.date + "'>" + post.display_date + "</time></a>";
        text += "</figcaption>";
        text += "<blockquote><p>";
        text += post.text;
        text += "</p></blockquote>";
        text += "</figure></li>";
      }
      text += "</ul>";
      return el.append(text);
    },
    timeline: function(helpers) {
      return {
        data: [],
        fetch: function(renderer, callback, options) {
          var data, posts, url,
            _this = this;
          if ($.cookie && options.cookie && (posts = $.cookie(options.cookie))) {
            data = JSON.parse(posts);
            if (data.length !== options.count) {
              $.removeCookie(options.cookie);
              return this.fetch(renderer, callback, options);
            } else {
              renderer(options, data);
              return callback(data);
            }
          } else {
            url = "https://alpha-api.app.net/stream/0/";
            if (options.username) {
              url += "users/@" + options.username + "/posts?include_deleted=0";
            }
            if (options.hashtag) {
              url += "posts/tag/" + options.hashtag + "?include_deleted=0";
            }
            if (options.before_id) {
              url += "&before_id=" + options.before_id;
            }
            if (!options.replies) {
              url += "&include_directed_posts=0";
            }
            url += "&callback=?";
            return $.ajax({
              url: url,
              dataType: 'jsonp',
              error: function(err) {
                console.error('Error fetching App.net timeline');
                return console.error(err);
              },
              success: function(response) {
                var post, _i, _len, _ref;
                if (!options.reposts) {
                  data = [];
                  _ref = response.data;
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    post = _ref[_i];
                    if (!post.repost_of) {
                      data.push(post);
                    }
                  }
                  response.data = data;
                }
                _this.data = _this.data.concat(response.data);
                if (_this.data.length < options.count) {
                  options.before_id = response.meta.min_id;
                  return _this.fetch(renderer, callback, options);
                } else {
                  _this.data = (function() {
                    var _j, _len1, _ref1, _results;
                    _ref1 = this.data.slice(0, options.count);
                    _results = [];
                    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                      post = _ref1[_j];
                      _results.push(helpers.postData(post, options));
                    }
                    return _results;
                  }).call(_this);
                  if ($.cookie && options.cookie) {
                    $.cookie(options.cookie, JSON.stringify(_this.data, {
                      path: '/'
                    }));
                  }
                  renderer(options, _this.data);
                  return callback(_this.data);
                }
              }
            });
          }
        }
      };
    },
    helpers: {
      trimUrl: function(url) {
        var max, part, parts, short, _i, _len, _ref;
        parts = [];
        max = 40;
        url = url.replace(/(https?:\/\/)/i, '');
        _ref = url.split('/');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          part = _ref[_i];
          if (!(parts.concat(part).join('/').length < max)) {
            break;
          }
          parts.push(part);
        }
        short = parts.join('/');
        if (url.length - short.length > 15) {
          short = url.slice(0, max);
        }
        if (short.length < url.length) {
          return short + '&hellip;';
        } else {
          return short;
        }
      },
      trimDisplayUrls: function(text) {
        var _this = this;
        return text.replace(/>\s*(https?:\/\/.+?)\s*</gi, function(match, p1) {
          return ">" + (_this.trimUrl(p1)) + "<";
        });
      },
      linkify: function(post) {
        var hashtag, mention, text, _i, _j, _len, _len1, _ref, _ref1;
        text = this.trimDisplayUrls(post.html);
        _ref = post.entities.mentions;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          mention = _ref[_i];
          text = text.replace(new RegExp("@(" + mention.name + ")", "gi"), "<a class='adn-username' href='https://alpha.app.net/$1'>@$1</a>");
        }
        _ref1 = post.entities.hashtags;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          hashtag = _ref1[_j];
          text = text.replace(new RegExp("#(" + hashtag.name + ")", "gi"), "<a class='adn-hashtag' href='https://alpha.app.net/hashtags/$1'>#$1</a>");
        }
        return text;
      },
      postData: function(post, options) {
        var avatar, repost;
        repost = !!post.repost_of;
        if (repost) {
          post = post.repost_of;
        }
        if (options.avatars) {
          avatar = post.user.avatar_image.url;
        }
        return {
          repost: repost,
          url: post.canonical_url,
          date: post.created_at,
          display_date: this.timeago(post.created_at),
          author: {
            username: post.user.username,
            name: post.user.name,
            url: post.user.canonical_url,
            avatar: avatar,
            unique: !!(options.reposts || options.hashtag)
          },
          text: this.linkify(post)
        };
      },
      timeago: function(time) {
        var days, hours, mins, say, secs, weeks;
        say = {
          just_now: "now",
          minute_ago: "1m",
          minutes_ago: "m",
          hour_ago: "1h",
          hours_ago: "h",
          yesterday: "1d",
          days_ago: "d",
          last_week: "1w",
          weeks_ago: "w"
        };
        secs = (new Date().getTime() - new Date(time).getTime()) / 1000;
        mins = Math.floor(secs / 60);
        hours = Math.floor(secs / 3600);
        days = Math.floor(secs / 86400);
        weeks = Math.floor(days / 7);
        if (isNaN(secs) || days < 0) {
          return '#';
        }
        if (days === 0) {
          if (secs < 60) {
            return say.just_now;
          } else if (secs < 120) {
            return say.minute_ago;
          } else if (secs < 3600) {
            return mins + say.minutes_ago;
          } else if (secs < 7200) {
            return say.hour_ago;
          } else {
            return hours + say.hours_ago;
          }
        } else {
          if (days === 1) {
            return say.yesterday;
          } else if (days < 7) {
            return days + say.days_ago;
          } else if (days === 7) {
            return say.last_week;
          } else {
            return weeks + say.weeks_ago;
          }
        }
      }
    }
  };

  if (typeof exports !== "undefined" && exports !== null) {
    if ((typeof module !== "undefined" && module !== null) && module.exports) {
      exports = module.exports = AdnTimeline;
    } else {
      exports.AdnTimeline = AdnTimeline;
    }
  } else {
    this.AdnTimeline = AdnTimeline;
  }

}).call(this);
