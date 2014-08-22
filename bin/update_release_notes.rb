#!/usr/bin/env ruby

require 'Date'
require 'redcarpet'
require 'optparse'

options = {
    :version => '',
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: update_release_notes.rb [options]"

  opts.on('-v version', '--version version', 'New version') do |version|
    options[:version] = version
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

$release_notes_html_file = 'release-notes.html'
$notes_directory = 'release-notes'

renderer = Redcarpet::Render::HTML.new(render_options = {})
markdown = Redcarpet::Markdown.new(renderer, extensions = {})

now = DateTime.now

markdown_string = options[:version] + ' — ' + now.strftime("%Y-%m-%d") + "\n\n"
notes = File.read("#{$notes_directory}/#{options[:version]}.md")
markdown_string += notes

result = markdown.render(markdown_string)

release_notes_html = <<END
<!DOCTYPE html>
<html>
<head>
  <title>Release Notes</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <link rel="stylesheet" type="text/css" href="css/releasenotes-style.css">
</head>
<body>

#{result}
</body>
</html>
END

File.open($release_notes_html_file, 'w') do |file|
  file.write(release_notes_html)
end

puts "Written to release-notes.html"
puts release_notes_html
