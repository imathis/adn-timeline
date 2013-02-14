require 'coffee-script'
require 'uglifier'

js = CoffeeScript.compile File.read("adn-timeline.coffee")
File.open("adn-timeline.js", 'w') { |f| f.write js }

ugjs = Uglifier.new.compile js
File.open("adn-timeline.min.js", 'w') { |f| f.write ugjs }

#system 'sass style.scss'
