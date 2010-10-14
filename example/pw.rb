#!/usr/bin/ruby1.9.1
require 'password'

# This example should work with 1.8 and 1.9
ctpw = ARGV[0]

#ctpw = `xxd -l 3 -p /dev/random`

unless ctpw.nil?
  puts ctpw
  password = Password.new(ctpw)
  crypted = password.crypt(Password::MD5)
  puts crypted
else
  puts "No password was provided."
end
