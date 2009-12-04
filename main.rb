#!/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), 'lib/DemoParser')

options = {:show => [], :score => true}
banner = 'Usage: %s [options] file' % $0
message_types = [:ctf, :chat, :server, :frag, :capture]
OptionParser.new do |opts|
    opts.banner = banner
    opts.on('-s', '--show [id]', 'Show messages by identifier', 'Identifiers: %s' % message_types.join(', ')) do |v|
        v = v.intern
        if v == :all
            options[:show] = message_types
        end
        if message_types.include? v
            options[:show] << v
        else
            puts opts
            exit
        end
    end
    opts.on('--no-score', 'Disable final score display') do 
        options[:score] = false
    end
    opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
    end
end.parse!
if ARGV.empty?
    puts banner
    exit
end

def print_team(v)
    v.sort { |a,b| b[1].frags <=> a[1].frags }.each do |h,k|
        puts '%-15s %-5d%-5d%6.2f%%' % [k.name, k.frags, k.deaths, k.accuracy]
    end
end

parser = DemoParser.new(ARGV[0], options[:show])
parser.parse do |players, teams, game_mode, map_name|
    break unless options[:score]
    puts '%s: %s' % [MODES[game_mode][0], map_name]
    players = players.select { |k,v| not v.spectator? }
    if MODES[game_mode][1]
        teams.sort { |a,b| b[1] <=> a[1] }.each do |t,s|
            pv = players.select { |k,v| v.team == t }
            next if pv.empty?
            puts '%s: %d' % [t, s]
            print_team(pv)
        end
    else
        print_team(players)
    end
end

