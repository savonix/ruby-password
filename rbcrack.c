/* rbcrack.c - a Ruby interface to CrackLib
 * 
 * $Id: rbcrack.c,v 1.20 2006/03/02 19:41:44 ianmacd Exp $
 *
 * Version : 0.5.3
 * Author  : Ian Macdonald <ian@caliban.org>
 *
 * Copyright (C) 2002-2006 Ian Macdonald
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2, or (at your option)
 *   any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software Foundation,
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <ruby.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <crack.h>

#include "rbcrack.h"


VALUE ePassword_DictionaryError;
VALUE ePassword_WeakPassword;


/* <b>check</b><em>(dict=nil)</em>
 *
 * This interfaces to LibCrack to check the strength of the password. If
 * _dict_ is given, it is the path to the CrackLib dictionary, minus the
 * file's extension. For example, if the dictionary is located at
 * <tt>/usr/lib/cracklib_dict.pwd</tt>, _dict_ would be
 * <tt>/usr/lib/cracklib_dict</tt>. If it is not given, the dictionary found
 * at build time will be used.
 *
 * If a path is given that does not lead to a legible dictionary, a
 * Password::DictionaryError exception is raised. On success, +true+ is
 * returned. On failure, a Password::WeakPassword exception is raised.
 */
static VALUE passwd_check(VALUE self, VALUE args)
{
    VALUE dict;
    char *objection;
    char *buffer;

    /* pop the one and only argument we may have been passed */
    dict = rb_ary_pop(args);

    if (dict == Qnil || strcmp(STR2CSTR(dict), "") == 0) {
	/* no argument passed, so use default location from rbcrack.h */
	dict = rb_str_new2(CRACK_DICT);
    } else {
	buffer = malloc(strlen(STR2CSTR(dict)) + 8);
	strcpy(buffer, STR2CSTR(dict));
	strcat(buffer, ".pwd");

	if (access(buffer, R_OK) != 0) {
	    free(buffer);
	    rb_raise(ePassword_DictionaryError, "%s", strerror(errno));
	}

	free(buffer);

    }

    /* perform check on password */
    objection = FascistCheck(STR2CSTR(self), STR2CSTR(dict));

    /* return true on success; raise an exception otherwise */
    if (objection) {
	rb_raise(ePassword_WeakPassword, "%s", objection);
    } else {
	return Qtrue;
    }

}

/* initialize this class */
void Init_crack()
{
    VALUE cPassword;

    /* define the Password class */
    cPassword = rb_define_class("Password", rb_cString);

    /* define the Password::DictionaryError exception */
    ePassword_DictionaryError =
	rb_define_class_under(cPassword, "DictionaryError",
			      rb_eStandardError);

    /* define the Password::WeakPassword exception */
    ePassword_WeakPassword =
	rb_define_class_under(cPassword, "WeakPassword",
			      rb_eStandardError);

    /* define the Password.check method */
    rb_define_method(cPassword, "check", passwd_check, -2);

    return;
}
