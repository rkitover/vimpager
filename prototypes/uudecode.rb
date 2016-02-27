#!/usr/local/bin/ruby

# uudecode for ruby, decodes stdin to stdout

gets

while line = gets
    break if line =~ /^end$/

    print line.unpack("u").join("")
end
