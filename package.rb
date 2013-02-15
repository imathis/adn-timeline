require 'coffee-script'
require 'uglifier'

js = CoffeeScript.compile File.read("adn-timeline.coffee")
File.open("javascripts/adn-timeline.js", 'w') { |f| f.write js }

ugjs = Uglifier.new.compile js
File.open("javascripts/adn-timeline.min.js", 'w') { |f| f.write ugjs }
