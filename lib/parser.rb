#!/bin/env ruby
require 'lib/binary_string'

class DemoParser
    attr_accessor :players, :teams, :game_mode
    def initialize(file, messages)
        @file = File.new(file, 'rb')
        ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
        @players = Hash.new { |h,k| h[k] = { :frags => 0, :deaths => 1 } }
        @teams = Hash.new { |h,k| h[k] = 0 }
        @messages = messages
        @identifiers = { :ctf => "CTF", :server => "Server", :frag => "Frag", :chat => "Chat" }
    end
    def parse(&block)
        raise 'Unrecognized format.' unless @file.read(16) == 'SAUERBRATEN_DEMO'
        raise 'Incompatible demo.' unless @file.read(8).unpack('ii') == [1, 257]
        while data = @file.read(12)
            time, channel, length = data.unpack('iii')
            raise 'Unknown channel.' unless channel < 2
            if channel == 1
                buffer = BinaryString.new @file.read(length)
                parse_messages(buffer, block)
            else
                @file.seek(length, IO::SEEK_CUR)
            end
        end
    end
    def parse_messages(buffer, block=nil, client=nil)
        while token = buffer.read_int
            case token
                when 0x02 # SV_WELCOME
                    buffer.read_int
                when 0x03 # SV_INITCLIENT
                    client_num = buffer.read_int
                    player = @players[client_num]
                    player[:name], player[:team] = buffer.read_string(2)
                    @teams[player[:team]]
                    player[:model] = buffer.read_int
                    print_message(:server, "%s connected" % player[:name])
                when 0x11 # SV_SPAWN
                    buffer.read_int(12)
                when 0x15 # SV_MAPCHANGE
                    map_name = buffer.read_string
                    @game_mode, _ = buffer.read_int(2)
                when 0x1c # SV_CLIENTPING
                    @players[client][:ping] = buffer.read_int
                when 0x1d # SV_TIMEUP
                    if buffer.read_int == 0 and not block.nil?
                        block.call(@players, @teams, @game_mode)
                    end
                when 0x22 # SV_RESUME
                    while client_num = buffer.read_int
                        if client_num < 0 then break end
                        @players[client_num][:info] = buffer.read_int(15)
                    end
                when 0x51 # SV_CLIENT
                    client_num = buffer.read_int
                    parse_messages(buffer.sub_buffer(buffer.read_uint), client=client_num)
                when 0x56 # SV_PAUSEGAME
                    buffer.read_int

                # Change player state
                when 0x07 # SV_CDIS - client disconnected
                    client_num = buffer.read_int
                    print_message(:server, "%s disconnected" % @players[client_num][:name])
                    @players.delete(client_num)
                when 0x36 # SV_CURRENTMASTER - player becomes master
                    @players[buffer.read_int][:priv] = buffer.read_int
                    # Clear all other privileges?
                when 0x37 # SV_SPECTATOR - player becomes spectator, or not spectator?
                    @players[buffer.read_int][:spectator] = buffer.read_int == 1
                when 0x39 # SV_SETTEAM
                    @players[buffer.read_int][:team] = buffer.read_string
                when 0x5f # SV_SWITCHNAME
                    name = buffer.read_string
                    print_message(:server, "Renamed %s to %s" % [@players[client][:name], name])
                    @players[client][:name] = name
                when 0x60 # SV_SWITCHMODEL
                    buffer.read_int

                # In game tokens
                when 0x06 # SV_SOUND
                    buffer.read_int
                when 0x0b # SV_DIED - player died?
                    victim, actor, frags = buffer.read_int(3)
                    @players[actor][:frags] = frags
                    @players[victim][:deaths] += 1
                    if @game_mode == 4 # team score = sum of player frags
                        @teams[@players[actor][:team]] += 1
                    end
                    print_message(:frag, "%s fragged (%d) %s" % [@players[actor][:name], frags, @players[victim][:name]])
                when 0x0c # SV_DAMAGE - player hit?
                    buffer.read_int(5)
                when 0x0d # SV_HITPUSH - ?
                    buffer.read_int(6)
                when 0x0e # SV_SHOTFX - weapon fired
                    buffer.read_int(7)
                when 0x13 # SV_GUNSELECT
                    buffer.read_int
                
                # Player messages
                when 0x05 # SV_TEXT
                    print_message(:chat, "%s: %s" % [@players[client][:name], buffer.read_string])
                when 0x20 # SV_SERVMSG
                    print_message(:server, remove_colors(buffer.read_string))
                
                # CTF mode tokens
                when 0x48 # SV_TAKEFLAG
                    client_num, flag = buffer.read_int(2)
                    print_message(:ctf, "%s took the %s flag" % [@players[client_num][:name], ["good", "evil"][flag-1]])
                when 0x49 # SV_RETURNFLAG
                    client_num, flag = buffer.read_int(2)
                    print_message(:ctf, "%s returned the %s flag" % [@players[client_num][:name], ["good", "evil"][flag-1]])
                when 0x4d # SV_DROPFLAG
                    buffer.read_int(5)
                when 0x4e # SV_SCOREFLAG
                    client_num, _, _, team, score = buffer.read_int(5)
                    @teams[["good", "evil"][team-1]] = score
                    print_message(:ctf, "%s scored" % @players[client_num][:name])
                when 0x4f # SV_INITFLAGS
                    buffer.read_int(3)

                else
                    puts 'Failed (at %d): %02x' % [buffer.position-1, token]
                    buffer.read_int(3).each { |i| if not i.nil? then puts '%02x' % i end }
                    exit
            end
        end
    end
    def print_message(id, msg)
        if @messages.include? id
            puts "%-10s %s" % [@identifiers[id], msg]
        end
    end
    def remove_colors(str)
        str.gsub(/\f./, '')
    end
    def DemoParser.finalize(id)
        @file.close()
    end
end

