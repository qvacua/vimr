#!/usr/bin/env ruby

require 'Date'
require 'optparse'

options = {
    :dry_run => false,
    :release => false,
    :version_leap => 'bugfix',
    :working_dir => '.',
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: app-release [options]"

  opts.on('-d', '--dry-run', 'Dry-run mode') do
    options[:dry_run] = true
  end

  opts.on('-r', '--release', 'Release build') do
    options[:release] = true
  end

  opts.on('-w', '--working-dir working-dir', 'Working directory') do |working_dir|
    options[:working_dir] = working_dir
  end

  opts.on('-v leap', '--version-leap leap', 'Version leap: major, minor or bugfix') do |leap|
    options[:version_leap] = leap
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

$dry_run = options[:dry_run]
$build_snapshot = !options[:release]
$working_dir = options[:working_dir]
version_leap = options[:version_leap]

$plist_buddy = '/usr/libexec/PlistBuddy -c '
$remote = 'origin'
$branch = `git rev-parse --abbrev-ref HEAD`

$plist_files_to_edit = %w(VimR/VimR-Info.plist StandardPlugins/Markdown/Markdown-Info.plist)

def do_when_release(command)
  puts command
  unless $dry_run
    `#{command}`
  end
end

def increment_bundle_version(plist_file)
  cur_bundle_str_version = `#{$plist_buddy} \"Print :CFBundleVersion\" #{plist_file}`.chomp
  new_bundle_version = cur_bundle_str_version

  if $build_snapshot
    puts "Building a SNAPSHOT #{plist_file}: not incrementing the bundle version (#{cur_bundle_str_version})"
  else
    new_bundle_version = cur_bundle_str_version.to_i + 1
    puts "Building a RELEASE #{plist_file}: incrementing CFBundleVersion: #{cur_bundle_str_version} ---> #{new_bundle_version}"

    do_when_release("#{$plist_buddy} \"Set :CFBundleVersion #{new_bundle_version}\" #{plist_file}")
  end

  new_bundle_version
end

def new_short_version_string(cur_short_str_version, version_leap)
  version_components = cur_short_str_version.split('.').collect { |component| component.to_i }

  case version_leap
    when "major"
      version_components[0] += 1
      version_components[1] = 0
      version_components[2] = 0
    when "minor"
      version_components[1] += 1
      version_components[2] = 0
    when "bugfix"
      version_components[2] += 1
    else
      version_components[2] += 1
  end

  version_components.join('.')
end

def increment_short_version_string(plist_file, version_leap)
  cur_short_str_version = `#{$plist_buddy} \"Print :CFBundleShortVersionString\" #{plist_file}`.chomp
  new_short_version = new_short_version_string(cur_short_str_version, version_leap)

  if $build_snapshot
    now = DateTime.now
    new_short_version += "-SNAPSHOT-" + now.strftime("%Y%m%d-%H%M")
    puts "Building a SNAPSHOT #{plist_file} CFBundleShortVersionString: #{cur_short_str_version} ---> #{new_short_version}"
  else
    puts "Building a RELEASE #{plist_file} CFBundleShortVersionString: #{cur_short_str_version} ---> #{new_short_version}"
  end

  do_when_release("#{$plist_buddy} \"Set :CFBundleShortVersionString #{new_short_version}\" #{plist_file}")
  new_short_version
end


Dir.chdir $working_dir
$plist_files_to_edit.each { |plist_file|
  increment_bundle_version(plist_file)
  increment_short_version_string(plist_file, version_leap)
}
