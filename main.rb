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
        positions = player.positions
        min_vals = Array.new(2) { |i| positions.values.collect { |a,b| [a,b][i] }.max }
        max_vals = Array.new(2) { |i| positions.values.collect { |a,b| [a,b][i] }.min }
        scale = Array.new(2) { |i| (max_vals[i] - min_vals[i]) / WIDTH.to_f }
        freq = positions.inject(Hash.new { |h,k| h[k] = 0 }) do |h, (k,v)|
            h[Array.new(2) {|i| ((v[i]-min_vals[i])/scale[i]).round }] += 1
            h
        end
        max_freq = freq.values.max
        puts player.name
        WIDTH.times do |x|
            WIDTH.times do |y|
                print (freq.include? [x,y]) ? (9.0 * freq[[x,y]] / max_freq).round : ' '
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

