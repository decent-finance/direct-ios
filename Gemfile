source "https://rubygems.org"

gem "fastlane"
gem "cocoapods"
gem "addressable"
gem "rubyzip", ">= 1.3.0"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
