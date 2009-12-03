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

def print_team(v, key=:frags)
    v.sort { |a,b| b[1][key] <=> a[1][key] }.each do |h,k|
        puts "%-15s %d\t%d" % [k[:name], k[:frags], k[:deaths]]
    end
end

def spectator?(v)
    v[:spectator] or (v.include? :info and v[:info][0] != 1)
end

parser = DemoParser.new(ARGV[0], options[:show])
parser.parse do |players, teams, game_mode|
    players = players.select { |k,v| not spectator? v }
    if [4, 6, 8, 9, 10, 11, 12, 13, 14].include? game_mode # team modes
        teams.sort { |a,b| b[1] <=> a[1] }.each do |t,s|
            pv = players.select { |k,v| v[:team] == t }
            if pv.empty? then next end
            puts "%s: %d" % [t, s]
            print_team(pv)
        end
    else
        print_team(players)
    end
    puts
end

