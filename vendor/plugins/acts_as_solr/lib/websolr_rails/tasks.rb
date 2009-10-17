#!/usr/bin/env ruby
Dir[File.join(File.dirname(__FILE__), "..", "tasks", "*.rake")].each do |file|
  load file
end