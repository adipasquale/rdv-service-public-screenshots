require "yaml"
require "optparse"
require "slim"
require "ostruct"
require_relative "structures"

#
# puts "stitching screenshots..."
# system "pngquant --ext .png --force #{File.join(@dirpath, '**/*.png')}"

# use optparse to get the directory patho
OptionParser.new do |opts|
  opts.banner = "Usage: build_site.rb [options]"
  opts.on("-d", "--dirpath DIRPATH", "Directory path that contains avant/ and après/ with screenshots") do |dirpath|
    @dirpath = dirpath
  end
end.parse!

unless @dirpath
  puts "Missing dirpath argument"
  exit 1
end

screenshots_groups = ScreenshotsGroup.build_from_yaml(dirpath: @dirpath)

html = Slim::Template.new(File.join(__dir__, "template.slim")).render(OpenStruct.new(screenshots_groups:))
File.write(File.join(@dirpath, "index.html"), html)
system "ln -s #{File.join(__dir__, 'style.css')} #{@dirpath}/style.css"
system "open #{@dirpath}/index.html"

# system "cp #{File.join(__dir__, 'style.css')} #{@dirpath}"
# system "open #{@dirpath}/index.html"
