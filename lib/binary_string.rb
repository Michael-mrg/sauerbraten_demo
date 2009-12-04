#!/bin/env ruby

class BinaryString < String
    attr_reader :position
    def initialize(str)
        super
        @position = 0
    end
    def read_int(num=0)
        return read_int(1)[0] if num == 0
        Array.new([0, [num, self.length-@position].min].max).collect do
            n = read_char
            if n == -128 # 16-bit
                n = self[@position..@position+1].unpack('s')[0]
                @position += 2
            elsif n == -127 # 32-bit
                n = self[@position..@position+3].unpack('l')[0]
                @position += 4
            end
            n
        end
    end
    def read_uint(num=0)
        return read_uint(1)[0] if num == 0
        Array.new([0, [num, self.length-@position].min].max).collect do
            n = read_char(0, 'C')
            [7, 14, 21].each do |i|
                n += (read_char(0, 'C') << i) - (1 << i) unless n & (1 << i) == 0
            end
            unless n & (1 << 28) == 0
                n |= 0xF0000000
            end
            n
        end
    end
    def read_string(num=0)
        return read_string(1)[0] if num == 0
        Array.new(num).collect do
            start, @position = @position, self.index("\x00", @position)+1
            self[start...@position-1]
        end
    end
    def read_char(num=0, type='c')
        return read_char(1, type)[0] if num == 0
        Array.new(num).collect do
            @position += 1
            self[@position-1].unpack(type)[0]
        end
    end
    def sub_buffer(length)
        @position += length
        BinaryString.new self[@position-length..@position-1]
    end
end

