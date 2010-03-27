#!/usr/bin/ruby -w
#
# $Id: example.rb,v 1.7 2004/04/07 09:49:06 ianmacd Exp $
#
# Copyright (C) 2002-2004 Ian Macdonald
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

require 'password'

def handle_password( pw )
  pw.check
  puts pw.crypt( `uname` == "Linux\n" ? Password::MD5 : Password::DES )
end

begin
  my_string = Password.get( "Password with get: " )
  handle_password( my_string )
rescue Password::WeakPassword => reason
  puts reason
  retry
end

begin
  my_string = Password.getc( "Password with getc: ", 'X' )
  handle_password( my_string )
rescue Password::WeakPassword => reason
  puts reason
  retry
end
