cp -r javascripts/adn-timeline.js _site/javascripts
cp -r javascripts/lib/*.js _site/javascripts/lib/
cp -r stylesheets/demo.css _site/stylesheets/demo.css
cp -r index.html _site/index.html
NOW=$(date +"%F %H:%M")
cd _site; git add -u && git add . && git commit -m "Site updated $NOW" && git push origin gh-pages; cd -
