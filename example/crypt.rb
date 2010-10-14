#!/usr/bin/ruby1.9.1
require 'password'

# This example should work with Ruby 1.9.1

ctpw = ARGV[0]

#ctpw = `xxd -l 3 -p /dev/random`

puts ctpw

cleartext = ctpw

password = Password.new(cleartext)
crypted = password.crypt()

puts crypted
