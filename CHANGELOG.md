## 1.3.1

- Added option to use global sass variables to set styles.

## 1.3

- AdnTimeline is now a class, instantiate with `new AdnTimeline([options])`.
- Now for reposts, post.reposted  contains a hash of the reposting account's username, name and url.
- Improved styling for reposted posts

## 1.2.1

- Removed some default styles for better visual compatability and less configuration.

## 1.2

- Added adn-timeline stylesheets (SCSS and CSS) for styled embedding.
- Now showing author information for hashtag timelines or when reposts are enabled.
- Fixed hashtag autolinking.
- Separated theme and layout into mixins (SCSS).
- Minor style improvents.
- Reorganized source and added deployment script for gh-pages site.

## 1.1

- Now fetches timelines for hashtags too.
- Optionally show avatars.
- Reposts and posts in hashtag timelines now include author data in the caption.
- Added `post.author.unique` and `post.repost` to post data.
- Improved markup and styles for author captions on reposts and hashtag timelines.

## 1.0.1

- Improved integration with jQuery methods
- Fixed username link

## 1.0
- Initial release
