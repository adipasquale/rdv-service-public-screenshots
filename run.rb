# bundle exec rails runner scripts/screenshots/run.rb

require "active_support/all"

# get the current git branch name
branch = `git rev-parse --abbrev-ref HEAD`

if branch == "production"
  puts "You are on the production branch. Please checkout to another branch."
  exit 1
end

# check that the branch is clean
if `git status --porcelain`.strip != ""
  puts "The branch is not clean. Please commit your changes."
  exit 1
end

# check that the rails server is up
if `lsof -i :3000`.strip == ""
  puts "The rails server is not up. Please start the server."
  exit 1
end

# get the current timestampq
timestamp = Time.now.strftime("%Y_%m_%d__%H_%M")

def run_command(command)
  puts "\n#{command} ..."
  res = system(command)
  puts
  res
end

output_dirname = "#{timestamp}_#{branch.parameterize}"
output_dirpath = File.join(__dir__, output_dirname)
output_dirpath_after = File.join(output_dirpath, "after")
output_dirpath_before = File.join(output_dirpath, "before")
puts "creating folders #{output_dirpath_before} and #{output_dirpath_after} ..."
FileUtils.mkdir_p([output_dirpath_before, output_dirpath_after])

run_command "OUTPUT_DIR=#{output_dirpath_after} RAILS_ENV=test ./bin/bundle exec rspec #{__dir__}/spec.rb"

exit(1) unless run_command("git checkout production")
puts "waiting 10s for webpacker ..."
sleep 10 # wait for webpacker to recompile

run_command "OUTPUT_DIR=#{output_dirpath_before} RAILS_ENV=test ./bin/bundle exec rspec #{__dir__}/spec.rb"

exit(1) unless run_command("git checkout -")

# pngs_path = File.join(output_dirpath, "**/*.png")
# run_command "pngquant --ext .png --force #{pngs_path}"
# run_command "mogrify -resize 60% #{pngs_path}"

puts "running build_site.rb ..."
exit(1) unless run_command("ruby #{__dir__}/build_site.rb -d #{output_dirpath}")
puts "done ✅"
