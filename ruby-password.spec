# $Id: ruby-password.spec,v 1.21 2006/03/02 19:53:18 ianmacd Exp $
#

Summary: A password handling library for Ruby with interface to CrackLib
Name: ruby-password
Version: 0.5.3
Release: 1
License: GPL
Group: Applications/Ruby
Source: http://www.caliban.org/files/ruby/%{name}-%{version}.tar.gz
URL: http://www.caliban.org/ruby/
Packager: Ian Macdonald <ian@caliban.org>
BuildRoot: /var/tmp/%{name}-%{version}
BuildRequires: ruby, cracklib, cracklib-dicts
Requires: ruby-termios, cracklib, cracklib-dicts

%define ruby18 %( [ `ruby -r rbconfig -e 'print Config::CONFIG["MAJOR"], ".", Config::CONFIG["MINOR"]'` = '1.8' ] && echo 1 || echo 0 )

# build documentation if we have rdoc on the build system
%define rdoc %( type rdoc > /dev/null && echo 1 || echo 0 )

%if %{ruby18}
Requires: ruby >= 1.8.0
%else
Requires: ruby >= 1.6.0
%endif

%description
Ruby/Password is a suite of password handling methods for Ruby. It supports
the manual entry of passwords from the keyboard in both buffered and
unbuffered modes, password strength checking, random password generation,
phonemic password generation (for easy memorisation by human-beings) and the
encryption of passwords.

%prep
%setup

%build
ruby extconf.rb
make

%clean
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install
install -d $RPM_BUILD_ROOT%{_mandir}/man1
install pwgen.1 $RPM_BUILD_ROOT%{_mandir}/man1
gzip -9 $RPM_BUILD_ROOT%{_mandir}/man1/pwgen.1
install -d $RPM_BUILD_ROOT%{_bindir}
install -m755 example/pwgen $RPM_BUILD_ROOT%{_bindir}
%if %{rdoc}
  rdocpath=`ruby -rrdoc/ri/ri_paths -e 'puts RI::Paths::PATH[1] ||
					     RI::Paths::PATH[0]'`
  rdoc -r -o $RPM_BUILD_ROOT$rdocpath -x CVS *.c lib
  rm $RPM_BUILD_ROOT$rdocpath/created.rid
%endif
find $RPM_BUILD_ROOT -type f -print | \
  ruby -pe 'sub(%r(^'$RPM_BUILD_ROOT'), "")' > %{name}-%{version}-filelist
%if %{rdoc}
  echo '%%docdir' $rdocpath >> %{name}-%{version}-filelist
%endif

find $RPM_BUILD_ROOT -type f -print | \
    ruby -pe 'sub(%r(^'$RPM_BUILD_ROOT'), "")' > %{name}-%{version}-filelist

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
%doc CHANGES COPYING INSTALL README
%doc example/example.rb

%changelog
* Thu Mar  2 2006 Ian Macdonald <ian@caliban.org> 0.5.3-1
- 0.5.3
- Build environment no longer uses packer.h if available.
- Package RDoc documentation in form usable by ri, rather than in HTML.

* Sat Sep  4 2004 Ian Macdonald <ian@caliban.org> 0.5.2-1
- 0.5.2
- Build environment modified to search for the system dictionary in the
  additional location of /var/cache/cracklib/cracklib_dict.pwd, which is where
  it is on Debian Linux.

* Mon Apr 12 2004 Ian Macdonald <ian@caliban.org> 0.5.1-1
- 0.5.1
- Password.get would throw an exception in the unlikely event that STDIN
  reached EOF without any input.
- pwgen now supports a -v or --version flag.

* Fri Apr  9 2004 Ian Macdonald <ian@caliban.org> 0.5.0-1
- 0.5.0
- A new example program, pwgen, has been added, complete with man page.
- A new class method, Password.phonemic, generates phonemic passwords.
- The old Password.random method has been renamed Password.urandom and
  replaced by a new, portable Password.random.
- Password.get will now detect whether STDIN is connected to a tty. If not, no
  password prompt is displayed and no attempt will be made to manipulate
  terminal echo.
- The prompt parameter to Password.get and Password.getc must now be passed in
  its entirety.
- Running password.rb directly will now result in a call to Password.phonemic
  and the display of the resulting password.
- The Password::BadDictionary exception has been renamed
  Password::DictionaryError and made a subclass of StandardError instead of
  RuntimeError.
- The CryptError exception has been moved to Password::CryptError and is now a
  subclass of StandardError instead of RuntimeError.
- A new constant, PASSWD_CHARS, gives the list of characters from which
  automatically generated passwords will be chosen. Note that Password.urandom
  will use the additional characters '+' and '/'.
- A new constant, SALT_CHARS, gives the list of characters valid as salt
  characters when invoking Password#crypt.
- Password.getc and Password.random now return an instance of Password, not
  String.
- A Password::CryptError exception is now raised if the salt passed to
  Password#crypt contains a bad character.
- RDoc documentation has been added.
- The old RD documentation has been removed.
- Unit-tests are now included with the software to verify its correct working.

* Wed Nov 12 2003 Ian Macdonald <ian@caliban.org> 0.4.1-1
- 0.4.1
- Warning in Ruby 1.8.x caused by use of rb_enable_super() has been fixed

* Wed Jun 10 2003 Ian Macdonald <ian@caliban.org> 0.4.0-1
- 0.4.0
- When a bad dictionary path is provided to Password#check, a
  Password::BadDictionary exception is now raised
- Turn off Ruby buffering for Password.getc, as this resulted in the prompt
  not being displayed when called by Ruby 1.8

* Wed Oct  2 2002 Ian Macdonald <ian@caliban.org> 0.3.0-1
- 0.3.0
- Password#check now raises a Password::WeakPassword exception when provided
  with a weak password

* Sat Sep 28 2002 Ian Macdonald <ian@caliban.org> 0.2.1-1
- 0.2.1
- Portability enhancements from Akinori MUSHA <knu@iDaemons.org>

* Wed Sep 18 2002 Ian Macdonald <ian@caliban.org> 0.2.0-1
- 0.2.0
- Password#check now returns true on success, and raises a Crack::WeakPassword
  exception on failure

* Tue Jun 18 2002 Ian Macdonald <ian@caliban.org> 0.1.1-1
- 0.1.1
- Password.get now returns an instance of Password, not String
- Password.new now defaults to assigning a null string

* Tue Jun 18 2002 Ian Macdonald <ian@caliban.org> 0.1.0-1
- 0.1.0
