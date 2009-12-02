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
        Array.new([num, self.length-@position].min).collect do
            n = self[@position].unpack('c')[0]
            @position += 1
#            if n == 0x80 # 16-bit
#                n = self.ord | (buffer.read(1).ord << 8)
#                @position += 2
#            elsif n == 0x81 # 32-bit
#                n = self[@position].ord | (buffer[@position+1].ord << 8) | (buffer.read(1).ord << 16) | (buffer.read(1).ord << 24)
#                @position += 4
#            end
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
end

class DemoParser
    attr_accessor :file, :players
    def initialize(file)
        @file = File.new(file, 'rb')
        ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
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
    def parse_messages(buffer)
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
                    @players = Hash.new
                    while (client_num = buffer.read_int) != -1
                        @players[client_num] = Hash.new
                        @players[client_num][:info] = buffer.read_int(15)
                    end
                when 0x03 # SV_INITCLIENT
                    client_num = buffer.read_int
                    player = @players[client_num]
                    if player.nil? then
                        #player = Hash.new    
                    end
                    player[:name], player[:team] = buffer.read_string(2)
                    player[:model] = buffer.read_int
                when 0x4f # SV_INITFLAGS
                    buffer.read_int(3)
                else
                    puts 'Failed (at %d): %02x' % [buffer.position-1, token]
                    buffer.read_int(3).each { |i| puts '%02x' % i }
                    exit
            end
        end
    end
    def DemoParser.finalize(id)
        @file.close()
    end
end

#DemoParser.new('2009_11_29_19_30_55-instagib_team-ot-psl_match_-_}tc{hero_vs.__rb_honzik1').parse
DemoParser.new('2009_11_30_00_50_35-insta_ctf-forge').parse
