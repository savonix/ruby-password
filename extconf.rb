# extconf for Ruby/Password
#
# $Id: extconf.rb,v 1.13 2006/03/02 17:35:06 ianmacd Exp $

require 'mkmf'

search_dicts = %w(
  /usr/local/lib/pw_dict.pwd
  /usr/lib/pw_dict.pwd
  /opt/lib/pw_dict.pwd
  /usr/local/lib/cracklib_dict.pwd
  /usr/lib/cracklib_dict.pwd
  /opt/lib/cracklib_dict.pwd
  /var/cache/cracklib/cracklib_dict.pwd
)

if dict = with_config('crack-dict')
  search_dicts.unshift(dict)
end

crack_dict = nil

# find the crack dictionary
print "checking for cracklib dictionary... "

search_dicts.each do |dict|
  # create a header file pointing to the crack dictionary
  if File.exist?(dict)
    puts dict
    crack_dict = dict.sub(/\.pwd/, '')
    break
  end
end

if crack_dict.nil?
  puts "no\nCouldn't find a cracklib dictionary on this system"
  exit 1
end

hfile = File.new("rbcrack.h", 'w')
hfile.printf("#define CRACK_DICT \"%s\"\n", crack_dict)
hfile.close

have_header('crack.h') && have_library('crack', 'FascistCheck') or exit 1

create_makefile('crack')

File.open('Makefile', 'a') do |f|
  f.print <<EOF

extra-clean:	distclean
		-rm -rf rbcrack.h doc/

docs:
		-rdoc -x CVS rbcrack.c lib

test:		crack.so FORCE
		-cd test; ./tc_password.rb

FORCE:
EOF
end
