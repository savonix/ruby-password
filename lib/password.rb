# $Id: password.rb,v 1.24 2006/03/02 19:42:33 ianmacd Exp $
# 
# Version : 0.5.3
# Author  : Ian Macdonald <ian@caliban.org>
#
# Copyright (C) 2002-2006 Ian Macdonald
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


require 'crack'
require 'termios'


# Ruby/Password is a collection of password handling routines for Ruby,
# including an interface to CrackLib for the purposes of testing password
# strength.
# 
#  require 'password'
#
#  # Define and check a password in code
#  pw = Password.new( "bigblackcat" )
#  pw.check
#
#  # Get and check a password from the keyboard
#  begin
#    password = Password.get( "New password: " )
#    password.check
#  rescue Password::WeakPassword => reason
#    puts reason
#    retry
#  end
#
#  # Automatically generate and encrypt a password
#  password = Password.phonemic( 12, Password:ONE_CASE | Password::ONE_DIGIT )
#  crypted = password.crypt
#
#
class Password < String

  # This exception class is raised if an error occurs during password
  # encryption when calling Password#crypt.
  #
  class CryptError < StandardError; end

  # This exception class is raised if a bad dictionary path is detected by
  # Password#check.
  #
  class DictionaryError < StandardError; end

  # This exception class is raised if a weak password is detected by
  # Password#check.
  #
  class WeakPassword < StandardError; end

  VERSION = '0.5.3'

  # DES algorithm
  # 
  DES = true

  # MD5 algorithm (see <em>crypt(3)</em> for more information)
  #
  MD5 = false
 
  # This flag is used in conjunction with Password.phonemic and states that a
  # password must include a digit.
  #
  ONE_DIGIT  =	1

  # This flag is used in conjunction with Password.phonemic and states that a
  # password must include a capital letter.
  #
  ONE_CASE    = 1 << 1

  # Characters that may appear in generated passwords. Password.urandom may
  # also use the characters + and /.
  #
  PASSWD_CHARS = '0123456789' +
		 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
		 'abcdefghijklmnopqrstuvwxyz'

  # Valid salt characters for use by Password#crypt.
  #
  SALT_CHARS   = '0123456789' +
		 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
		 'abcdefghijklmnopqrstuvwxyz' +
		 './'

  # :stopdoc:

  # phoneme flags
  #
  CONSONANT = 1
  VOWEL	    = 1 << 1
  DIPHTHONG = 1 << 2
  NOT_FIRST = 1 << 3  # indicates that a given phoneme may not occur first

  PHONEMES = {
    :a	=> VOWEL,
    :ae	=> VOWEL      | DIPHTHONG,
    :ah => VOWEL      | DIPHTHONG,
    :ai => VOWEL      | DIPHTHONG,
    :b	=> CONSONANT,
    :c	=> CONSONANT,
    :ch	=> CONSONANT  | DIPHTHONG,
    :d	=> CONSONANT,
    :e	=> VOWEL,
    :ee	=> VOWEL      | DIPHTHONG,
    :ei	=> VOWEL      | DIPHTHONG,
    :f	=> CONSONANT,
    :g	=> CONSONANT,
    :gh	=> CONSONANT  | DIPHTHONG | NOT_FIRST,
    :h	=> CONSONANT,
    :i	=> VOWEL,
    :ie	=> VOWEL      | DIPHTHONG,
    :j	=> CONSONANT,
    :k	=> CONSONANT,
    :l	=> CONSONANT,
    :m	=> CONSONANT,
    :n	=> CONSONANT,
    :ng	=> CONSONANT  | DIPHTHONG | NOT_FIRST,
    :o	=> VOWEL,
    :oh	=> VOWEL      | DIPHTHONG,
    :oo	=> VOWEL      | DIPHTHONG,
    :p	=> CONSONANT,
    :ph	=> CONSONANT  | DIPHTHONG,
    :qu	=> CONSONANT  | DIPHTHONG,
    :r	=> CONSONANT,
    :s	=> CONSONANT,
    :sh	=> CONSONANT  | DIPHTHONG,
    :t	=> CONSONANT,
    :th	=> CONSONANT  | DIPHTHONG,
    :u	=> VOWEL,
    :v	=> CONSONANT,
    :w	=> CONSONANT,
    :x	=> CONSONANT,
    :y	=> CONSONANT,
    :z	=> CONSONANT
  }

  # :startdoc:


  # Turn local terminal echo on or off. This method is used for securing the
  # display, so that a soon to be entered password will not be echoed to the
  # screen. It is also used for restoring the display afterwards.
  #
  # If _masked_ is +true+, the keyboard is put into unbuffered mode, allowing
  # the retrieval of characters one at a time. _masked_ has no effect when
  # _on_ is +false+. You are unlikely to need this method in the course of
  # normal operations.
  #
  def Password.echo(on=true, masked=false)
    term = Termios::getattr( $stdin )

    if on
      term.c_lflag |= ( Termios::ECHO | Termios::ICANON )
    else # off
      term.c_lflag &= ~Termios::ECHO
      term.c_lflag &= ~Termios::ICANON if masked
    end

    Termios::setattr( $stdin, Termios::TCSANOW, term )
  end


  # Get a password from _STDIN_, using buffered line input and displaying
  # _message_ as the prompt. No output will appear while the password is being
  # typed. Hitting <b>[Enter]</b> completes password entry. If _STDIN_ is not
  # connected to a tty, no prompt will be displayed.
  #
  def Password.get(message="Password: ")
    begin
      if $stdin.tty?
	Password.echo false
	print message if message
      end

      pw = Password.new( $stdin.gets || "" )
      pw.chomp!

    ensure
      if $stdin.tty?
	Password.echo true
	print "\n"
      end
    end
  end


  # Get a password from _STDIN_ in unbuffered mode, i.e. one key at a time.
  # _message_ will be displayed as the prompt and each key press with echo
  # _mask_ to the terminal. There is no need to hit <b>[Enter]</b> at the end.
  #
  def Password.getc(message="Password: ", mask='*')
    # Save current buffering mode
    buffering = $stdout.sync

    # Turn off buffering
    $stdout.sync = true

    begin
      Password.echo(false, true)
      print message if message
      pw = ""

      while ( char = $stdin.getc ) != 10 # break after [Enter]
	putc mask
	pw << char
      end

    ensure
      Password.echo true
      print "\n"
    end

    # Restore original buffering mode
    $stdout.sync = buffering

    Password.new( pw )
  end


  # :stopdoc:
  
  # Determine whether next character should be a vowel or consonant.
  #
  def Password.get_vowel_or_consonant
    rand( 2 ) == 1 ? VOWEL : CONSONANT
  end

  # :startdoc:


  # Generate a memorable password of _length_ characters, using phonemes that
  # a human-being can easily remember. _flags_ is one or more of
  # <em>Password::ONE_DIGIT</em> and <em>Password::ONE_CASE</em>, logically
  # OR'ed together. For example:
  #
  #  pw = Password.phonemic( 8, Password::ONE_DIGIT | Password::ONE_CASE )
  #
  # This would generate an eight character password, containing a digit and an
  # upper-case letter, such as <b>Ug2shoth</b>.
  #
  # This method was inspired by the
  # pwgen[http://sourceforge.net/projects/pwgen/] tool, written by Theodore
  # Ts'o.
  #
  # Generated passwords may contain any of the characters in
  # <em>Password::PASSWD_CHARS</em>.
  #
  def Password.phonemic(length=8, flags=nil)

    pw = nil
    ph_flags = flags

    loop do

      pw = ""

      # Separate the flags integer into an array of individual flags
      feature_flags = [ flags & ONE_DIGIT, flags & ONE_CASE ]

      prev = []
      first = true
      desired = Password.get_vowel_or_consonant

      # Get an Array of all of the phonemes
      phonemes = PHONEMES.keys.map { |ph| ph.to_s }
      nr_phonemes = phonemes.size

      while pw.length < length do

	# Get a random phoneme and its length
	phoneme = phonemes[ rand( nr_phonemes ) ]
	ph_len = phoneme.length

	# Get its flags as an Array
	ph_flags = PHONEMES[ phoneme.to_sym ]
	ph_flags = [ ph_flags & CONSONANT, ph_flags & VOWEL,
		     ph_flags & DIPHTHONG, ph_flags & NOT_FIRST ]

	# Filter on the basic type of the next phoneme
	next if ph_flags.include? desired

	# Handle the NOT_FIRST flag
	next if first and ph_flags.include? NOT_FIRST

	# Don't allow a VOWEL followed a vowel/diphthong pair
	next if prev.include? VOWEL and ph_flags.include? VOWEL and
		ph_flags.include? DIPHTHONG

	# Don't allow us to go longer than the desired length
	next if ph_len > length - pw.length

	# We've found a phoneme that meets our criteria
	pw << phoneme

	# Handle ONE_CASE
	if feature_flags.include? ONE_CASE

	  if (first or ph_flags.include? CONSONANT) and rand( 10 ) < 3
	    pw[-ph_len, 1] = pw[-ph_len, 1].upcase
	    feature_flags.delete ONE_CASE
	  end

	end

	# Is password already long enough?
	break if pw.length >= length

	# Handle ONE_DIGIT
	if feature_flags.include? ONE_DIGIT
	  if ! first and rand( 10 ) < 3
	    pw << ( rand( 10 ) + ?0.ord ).chr
	    feature_flags.delete ONE_DIGIT

	    first = true
	    prev = []
	    desired = Password.get_vowel_or_consonant
	    next
	  end

	end

	if desired == CONSONANT
	  desired = VOWEL
	elsif prev.include? VOWEL or ph_flags.include? DIPHTHONG or
	      rand(10) > 3
	  desired = CONSONANT
	else
	  desired = VOWEL
	end

	prev = ph_flags
	first = false
      end

      # Try again
      break unless feature_flags.include? ONE_CASE or
		   feature_flags.include? ONE_DIGIT

    end

    Password.new( pw )

  end


  # Generate a random password of _length_ characters. Unlike the
  # Password.phonemic method, no attempt will be made to generate a memorable
  # password. Generated passwords may contain any of the characters in
  # <em>Password::PASSWD_CHARS</em>.
  #
  #
  def Password.random(length=8)
    pw = ""
    nr_chars = PASSWD_CHARS.size

    length.times { pw << PASSWD_CHARS[ rand( nr_chars ) ] }

    Password.new( pw )
  end


  # An alternative to Password.random. It uses the <tt>/dev/urandom</tt>
  # device to generate passwords, returning +nil+ on systems that do not
  # implement the device. The passwords it generates may contain any of the
  # characters in <em>Password::PASSWD_CHARS</em>, plus the additional
  # characters + and /.
  #
  def Password.urandom(length=8)
    return nil unless File.chardev? '/dev/urandom'

    rand_data = nil
    File.open( "/dev/urandom" ) { |f| rand_data = f.read( length ) }

    # Base64 encode it
    Password.new( [ rand_data ].pack( 'm' )[ 0 .. length - 1 ] )
  end


  # Encrypt a password using _type_ encryption. _salt_, if supplied, will be
  # used to perturb the encryption algorithm and should be chosen from the
  # <em>Password::SALT_CHARS</em>. If no salt is given, a randomly generated
  # salt will be used.
  #
  def crypt(type=DES, salt='')

    unless ( salt.split( // ) - SALT_CHARS.split( // ) ).empty?
      raise CryptError, 'bad salt'
    end

    salt = Password.random( type ? 2 : 8 ) if salt.empty?

    # (Linux glibc2 interprets a salt prefix of '$1$' as a call to use MD5
    # instead of DES when calling crypt(3))
    salt = '$1$' + salt if type == MD5

    # Pass to crypt in class String (our parent class)
    crypt = super( salt )

    # Raise an exception if MD5 was wanted, but result is not recognisable
    if type == MD5 && crypt !~ /^\$1\$/
      raise CryptError, 'MD5 not implemented'
    end

    crypt
  end

end


# Display a phonemic password, if run directly.
#
if $0 == __FILE__
  puts Password.phonemic
end
