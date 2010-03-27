#!/usr/bin/ruby -w
#
# $Id: tc_password.rb,v 1.3 2004/04/12 08:50:06 ianmacd Exp $

$: << File.dirname(__FILE__) + "/.." << File.dirname(__FILE__) + "/../lib"

require 'test/unit'
require 'password'


TIMES = 1000
LENGTH = 32


class TC_PasswordTest < Test::Unit::TestCase

  def test_check
    # Check for a weak password.
    pw = Password.new( 'foo' )
    assert_raises( Password::WeakPassword ) { pw.check }

    # Check for a good password.
    pw = Password.new( 'G@7flAxg' )
    assert_nothing_raised { pw.check }

    # Check for an exception on bad dictionary path.
    assert_raises( Password::DictionaryError ) { pw.check( '/tmp/nodict' ) }
  end

  def test_phonemic
    TIMES.times do |t|
      pw = Password.phonemic( LENGTH )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_phonemic_one_case
    TIMES.times do |t|
      pw = Password.phonemic( LENGTH, Password::ONE_CASE )
      assert( pw =~ /[A-Z]/, "#{pw} has no upper-case letter" )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_phonemic_one_digit
    TIMES.times do |t|
      pw = Password.phonemic( LENGTH, Password::ONE_DIGIT )
      assert( pw =~ /[0-9]/, "#{pw} has no digit" )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_phonemic_one_case_one_digit
    TIMES.times do |t|
      pw = Password.phonemic( LENGTH, Password::ONE_CASE |
				      Password::ONE_DIGIT )
      assert( pw =~ /[A-Z]/, "#{pw} has no upper-case letter" )
      assert( pw =~ /[0-9]/, "#{pw} has no digit" )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_random
    TIMES.times do |t|
      pw = Password.random( LENGTH )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_urandom
    TIMES.times do |t|
      pw = Password.urandom( LENGTH )
      assert( pw.length == LENGTH, "bad length: #{pw.length}, not #{LENGTH}" )
    end
  end

  def test_crypt
    pw = Password.random( LENGTH )
    assert_nothing_raised { pw.crypt( Password::DES ) }
    assert_nothing_raised { pw.crypt( Password::MD5 ) }
    assert_raises( Password::CryptError ) { pw.crypt( Password::DES, '@*' ) }
  end

  def test_null_stdin
    $stdin.reopen( File.new( '/dev/null' ) )
    assert_nothing_raised { Password.get }
  end

end
