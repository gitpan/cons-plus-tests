#! /usr/bin/env perl
#
#	Compile a single executable from a single .c file in the
#	local directory, which includes a single .h file from the
#	local directory.   The #include file name is specified with
#	double-quotes.
#

# $Id: t0012.t,v 1.3 2000/06/01 22:00:44 knight Exp $

# Copyright (c) 1996-2000 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

use Test::Cmd::Cons qw($_exe);

$test = Test::Cmd::Cons->new(string => 'single-module #include "..."');

#
$foo_exe = "foo$_exe";

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write('foo.c', <<'_EOF_');
#include "foo.h"	/* make sure "comments" are not matched */
int
main(int argc, char *argv[])
{
	printf(STRING);
	exit (0);
}
_EOF_

$test->write('foo.h', <<'_EOF_');
#define	STRING	"This is the first foo.h file.\n"
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
This is the first foo.h file.
_EOF_

$test->write('foo.h', <<'_EOF_');
#define	STRING	"This is foo.h file number two!\n"
_EOF_

$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
This is foo.h file number two!
_EOF_

#
$test->pass;
__END__
