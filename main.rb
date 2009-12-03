#!/bin/env ruby
require 'optparse'
require 'lib/parser'

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

def print_team(v, key=:frags)
    v.sort { |a,b| b[1][key] <=> a[1][key] }.each do |h,k|
        puts '%-15s %-5d%d' % [k[:name], k[:frags], k[:deaths]]
    end
end

parser = DemoParser.new(ARGV[0], options[:show])
parser.parse do |players, teams, game_mode, map_name|
    if not options[:score] then break end
    puts map_name
    players = players.select { |k,v| not v[:spectator] and (not v.include? :info or v[:info][0] == 1) }
    if [4, 6, 8, 9, 10, 11, 12, 13, 14].include? game_mode # team modes
        teams.sort { |a,b| b[1] <=> a[1] }.each do |t,s|
            pv = players.select { |k,v| v[:team] == t }
            if pv.empty? then next end
            puts '%s: %d' % [t, s]
            print_team(pv)
        end
    else
        print_team(players)
    end
end

