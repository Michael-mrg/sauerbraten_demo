#!/bin/env ruby

class BinaryString < String
    attr_accessor :position
    def initialize(str)
        super
        @position = 0
    end
    def read_int(num=0)
        if num == 0 then
            return read_int(1)[0]
        end
        Array.new([0, [num, self.length-@position].min].max).collect do
            n = self[@position].unpack('c')[0]
            @position += 1
            if n == -128 # 16-bit
                n = self[@position..@position+1].unpack('l')[0]
                @position += 2
            elsif n == -127 # 32-bit
                n = self[@position..@position+3].unpack('l')[0]
                @position += 4
            end
            n
        end
    end
    def read_uint(num=0)
        if num == 0 then
            return read_uint(1)[0]
        end
        Array.new([0, [num, self.length-@position].min].max).collect do
            n = read_int
            [7,14,21].each do |i|
                if n & (1 << i) != 0
                    n += (read_int << i) - (1 << i)
                end
            end
            if n & (1 << 28) then
                n |= 0xF0000000
            end
            n
        end
    end
    def read_string(num=0)
        if num == 0 then
            return read_string(1)[0]
        end
        Array.new(num).collect do
            start, @position = @position, self.index("\x00", @position)+1
            self[start...@position-1]
        end
    end
    def sub_buffer(length)
        @position += length
        BinaryString.new self[@position-length..@position-1]
    end
end

class DemoParser
    attr_accessor :file, :players
    def initialize(file)
        @file = File.new(file, 'rb')
        ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
        @players = Hash.new { |h,k| h[k] = Hash.new }
    end
    def parse
        raise 'Unrecognized format.' unless @file.read(16) == 'SAUERBRATEN_DEMO'
        raise 'Incompatible demo.' unless @file.read(8).unpack('ii') == [1, 257]
        while data = file.read(12)
            time, channel, length = data.unpack('iii')
            raise 'Unknown channel.' unless channel < 2
            buffer = BinaryString.new @file.read(length)
            [method(:parse_positions), method(:parse_messages)][channel].call(buffer)
        end
    end
    def parse_positions(buffer)
    end
    def parse_messages(buffer, client=nil)
        while token = buffer.read_int
            case token
                when 0x02 # SV_WELCOME
                    buffer.read_int
                when 0x15 # SV_MAPCHANGE
                    map_name = buffer.read_string
                    game_mode, not_got_items = buffer.read_int(2)
                when 0x1d # SV_TIMEUP
                    buffer.read_int
                when 0x22 # SV_RESUME
                    while client_num = buffer.read_int
                        if client_num < 0 then break end
                        @players[client_num][:info] = buffer.read_int(15)
                    end
                when 0x03 # SV_INITCLIENT
                    client_num = buffer.read_int
                    player = @players[client_num]
                    player[:name], player[:team] = buffer.read_string(2)
                    player[:model] = buffer.read_int
                when 0x4f # SV_INITFLAGS
                    buffer.read_int(3)
                when 0x51 # SV_CLIENT
                    client_num = buffer.read_int
                    parse_messages(buffer.sub_buffer(buffer.read_uint), client_num)
                when 0x1c # SV_CLIENTPING
                    @players[client][:ping] = buffer.read_int
                when 0x11 # SV_SPAWN
                    buffer.read_int(12)
                when 0x56 # SV_PAUSEGAME
                    buffer.read_int
                when 0x20 # SV_SERVMSG
                    p remove_colors(buffer.read_string)
                when 0x07 # SV_CDIS - client disconnected
                    client_num = buffer.read_int
                    puts 'Disconnect: %s (%d)' % [@players[client_num][:name],client_num]
                when 0x0e # SV_SHOTFX - weapon fired
                    buffer.read_int(7)
                when 0x0c # SV_DAMAGE - player hit?
                    buffer.read_int(5)
                when 0x0d # SV_HITPUSH - ?
                    buffer.read_int(6)
                when 0x0b # SV_DIED - player died?
                    buffer.read_int(3)
                when 0x37 # SV_SPECTATOR - player becomes spectator, or not spectator?
                    @players[buffer.read_int][:spectator] = buffer.read_int == 1
                when 0x36 # SV_CURRENTMASTER - player becomes master
                    @players[buffer.read_int][:priv] = buffer.read_int
                    # Clear all other privileges?
                when 0x06 # SV_SOUND
                    buffer.read_int
                when 0x60 # SV_SWITCHMODEL
                    buffer.read_int
                when 0x39 # SV_SETTEAM
                    @players[buffer.read_int][:team] = buffer.read_string
                when 0x5f # SV_SWITCHNAME
                    name = buffer.read_string
                    puts 'Renamed %s -> %s' % [@players[client][:name], name]
                    @players[client][:name] = name
                when 0x05 # SV_TEXT
                    puts '%s: %s' % [@players[client][:name], buffer.read_string]
                else
                    puts 'Failed (at %d): %02x' % [buffer.position-1, token]
                    buffer.read_int(3).each { |i| if not i.nil? then puts '%02x' % i end }
                    exit
            end
        end
    end
    def remove_colors(str)
        str.gsub(/\f\d/, '')
    end
    def DemoParser.finalize(id)
        @file.close()
    end
end

DemoParser.new('2009_11_29_19_30_55-instagib_team-ot-psl_match_-_}tc{hero_vs.__rb_honzik1').parse
#DemoParser.new('2009_11_30_00_50_35-insta_ctf-forge').parse
