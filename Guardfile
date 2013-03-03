require 'coffee-script'
require 'uglifier'

guard :compass do
  watch %r{^stylesheets/(.*)\.s[ac]ss$}
end

guard :shell do
  watch /^javascripts\/.+\.coffee/ do |change|
    js = CoffeeScript.compile File.read(change.first)
    out = "javascripts/adn-timeline.js"
    outmin = "javascripts/adn-timeline.min.js"
    File.open(out, 'w') { |f| f.write js }

    ugjs = Uglifier.new.compile File.read("javascripts/adn-timeline.js")
    File.open(outmin, 'w') { |f| f.write ugjs }

    "Coffeescript compiled to #{out} and #{outmin}."
  end
end
