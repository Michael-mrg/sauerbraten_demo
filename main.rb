#!/bin/env ruby
require 'optparse'
require 'lib/parser'

options = {:show => []}
banner = "Usage: %s [options] file" % $0
OptionParser.new do |opts|
    opts.banner = banner
    opts.on("--show [id]", "Show messages by identifier") do |v|
        if v == "all"
            options[:show] = [:ctf, :chat, :server, :frag]
        end
        options[:show] << v.intern
    end
end.parse!
if ARGV.empty?
    puts banner
    exit
end

parser = DemoParser.new(ARGV[0], options[:show])
parser.parse
parser.players.sort { |a,b| b[1][:frags] <=> a[1][:frags] }.each do |h,k|
    puts "%-15s %d\t%d" % [k[:name], k[:frags], k[:deaths]]
end

