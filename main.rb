#!/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), 'lib/DemoParser')

options = {:show => [], :score => true, :track => []}
banner = 'Usage: %s [options] file' % $0
message_types = [:ctf, :chat, :server, :frag, :capture]
OptionParser.new do |opts|
    def help(opts)
        puts opts
        exit
    end
    opts.banner = banner
    opts.on('-s', '--show [id]', 'Show messages by identifier', 'Identifiers: %s' % message_types.join(', ')) do |v|
        v = v.intern
        options[:show] = message_types if v == :all
        help opts unless message_types.include? v
        options[:show] << v
    end
    opts.on('--no-score', 'Disable final score display') do 
        options[:score] = false
    end
    opts.on_tail('-h', '--help', 'Show this message') do
        help opts
    end
    opts.on('-t', '--track-position [client number]', 'Display chart of player\'s movements') do |v|
        help opts if v.to_i == 0 and v[0] != "0"
        options[:track] << v.to_i
    end
end.parse!
if ARGV.empty?
    puts banner
    exit
end

def print_team(v)
    puts '%-9s%-10s%-5s%-5s   %s' % ['#', 'Name', 'K', 'D', 'Acc']
    v.sort { |a,b| b[1].frags <=> a[1].frags }.each do |k,v|
        puts '%2d %-15s %-5d%-5d%6.2f%%' % [k, v.name, v.frags, v.deaths, v.accuracy]
    end
end

parser = DemoParser.new(ARGV[0], options[:show], options[:track])
parser.parse do |players, teams, game_mode, map_name|
    players = players.select { |k,v| not v.spectator }
    WIDTH = 25
    options[:track].each do |cn|
        unless players.include? cn
            puts 'Invalid client %d' % cn
            next
        end
        player = players[cn]
        positions = player.positions.collect { |i| i[0..1] }
        max_x_pos = positions.max[0]
        min_x_pos = positions.min[0]
        max_y_pos = positions.max { |a,b| a[1] <=> b[1] }[1]
        min_y_pos = positions.min { |a,b| a[1] <=> b[1] }[1]
        x_scale = (max_x_pos - min_x_pos) / WIDTH
        y_scale = (max_y_pos - min_y_pos) / WIDTH
        positions.collect! { |i| [ (i[0] - min_x_pos) / x_scale, (i[1] - min_y_pos) / y_scale ] }
        puts player.name
        WIDTH.times do |x|
            WIDTH.times do |y|
                print (positions.include? [x,y]) ? 'x' : ' '
            end
            puts
        end
        puts
    end
    
    break unless options[:score]
    puts '%s: %s' % [MODES[game_mode][0], map_name]
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

