#!/bin/env ruby

class BinaryString < String
    attr_reader :position
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

