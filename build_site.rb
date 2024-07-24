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
  opts.on("-d", "--dirpath DIRPATH", "Directory path that contains before/ and after/ with screenshots") do |dirpath|
    @dirpath = dirpath
  end
end.parse!

unless @dirpath
  puts "Missing dirpath argument"
  exit 1
end

yaml_tree = YAML.load_file(File.join(__dir__, "screenshots.yaml"))

screenshots_groups = yaml_tree.map do |group_name, screenshots_names|
  group = ScreenshotsGroup.new(group_name)
  screenshots_names.each do |name|
    group.screenshots << Screenshot.new(viewport: :desktop, name:, group:)
    group.screenshots << Screenshot.new(viewport: :mobile, name:, group:)
  end
  group
end

# require "byebug"
# byebug

html = Slim::Template.new(File.join(__dir__, "template.slim")).render(OpenStruct.new(screenshots_groups:))
File.write(File.join(@dirpath, "index.html"), html)
system "ln -s #{File.join(__dir__, 'style.css')} #{@dirpath}/style.css"
system "open #{@dirpath}/index.html"

# system "cp #{File.join(__dir__, 'style.css')} #{@dirpath}"
# system "open #{@dirpath}/index.html"
