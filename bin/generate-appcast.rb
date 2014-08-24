#!/usr/bin/env ruby

require 'Date'
require 'redcarpet'
require 'optparse'

options = {
    :short_version => '',
    :bundle_version => '',
    :sign => '',
    :size => '',
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: update_release_notes.rb [options]"

  opts.on('-v version', '--short-version version', 'Short version, eg 1.2.3') do |version|
    options[:short_version] = version
  end

  opts.on('-b bundle_version', '--bundle-version bundle_version', 'Bundle version, eg 134') do |bundle_version|
    options[:bundle_version] =bundle_version
  end

  opts.on('-s sign', '--signature sign', 'Appcast signature') do |sign|
    options[:sign] = sign
  end

  opts.on('-l size', '--size size', 'File size') do |size|
    options[:size] = size
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

$notes_directory = 'data'
$appcast_template = 'data/appcast-template.xml'
$appcast = 'appcast.xml'

renderer = Redcarpet::Render::HTML.new(render_options = {})
markdown = Redcarpet::Markdown.new(renderer, extensions = {})

now = DateTime.now

date_time = now.strftime("%Y-%m-%d %H:%M:%S")
description = markdown.render(File.read("#{$notes_directory}/#{options[:short_version]}.md")).chomp

template = File.read($appcast_template)
result = template.gsub(/#SHORT_VERSION#/, options[:short_version])
result = result.gsub(/#BUNDLE_VERSION#/, options[:bundle_version])
result = result.gsub(/#DESCRIPTION#/, description)
result = result.gsub(/#DATE_TIME#/, date_time)
result = result.gsub(/#SIGNATURE#/, options[:sign])
result = result.gsub(/#SIZE#/, options[:size])

File.open($appcast, 'w') do |file|
  file.write(result)
end

puts "Written to appcast.xml"
puts result

# 2014-08-19 22:40:11