#!/usr/bin/ruby1.9.1
require 'password'

# This example should work with both 1.8 and 1.9
ctpw = ARGV[0]

#ctpw = `xxd -l 3 -p /dev/random`

puts ctpw

cleartext = ctpw
puts cleartext
password = Password.new(cleartext)
crypted = password.crypt(Password::MD5)

puts crypted
