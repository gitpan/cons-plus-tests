#! /usr/bin/env perl
#
#	Compile an executable from a single .c file in the local
#	directory.  The .c file includes one local .h file
#	(double-quote #include) and one subdirectory .h file
#	(angle-bracke #include).  Specify "Ignore '^subdirectory/"
#	in the Construct file.  Build the executable by invoking
#	cons.  Update the subdirectory's .h files and invoke cons
#	again; check that it ignored the update .h file and did
#	NOT rebuild the executable.  Update the local .h file and
#	invoke cons again; check that it rebuilt the executable,
#	picking up the changes to both .h files.
#

# $Id: t0026.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Ignore');

$test->subdir('include');

#
$foo_exe = "foo$_exe";

#
$test->write('Construct', <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = '.';
\$env = new cons ( \%env_hash );
# The "include" should really have a trailing directory separatory,
# but working out the write regular-expression garp to get a proper
# Windows-NT backslash through the many layers is just too difficult.
# Leave it alone (for now) even though it means this test isn't as
# 100% correct as it should be.
Ignore '^include';
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write('foo.c', <<'_EOF_');
#include "local.h"
#include <include/foo.h>
int
main(int argc, char *argv[])
{
	printf("This is the foo.c file:\n");
	printf("\tlocal.h version %d\n", LOCAL_VERSION);
	printf("\tfoo.h version %d\n", FOO_VERSION);
	exit (0);
}
_EOF_

$test->write('local.h', <<'_EOF_');
#define	LOCAL_VERSION	11
_EOF_

$test->write(['include', 'foo.h'], <<'_EOF_');
#define	FOO_VERSION	21
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
This is the foo.c file:
	local.h version 11
	foo.h version 21
_EOF_

$test->write(['include', 'foo.h'], <<'_EOF_');
#define	FOO_VERSION	22
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
This is the foo.c file:
	local.h version 11
	foo.h version 21
_EOF_

$test->write('local.h', <<'_EOF_');
#define	LOCAL_VERSION	12
_EOF_

$test->write(['include', 'foo.h'], <<'_EOF_');
#define	FOO_VERSION	23
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
This is the foo.c file:
	local.h version 12
	foo.h version 23
_EOF_

#
$test->pass;
__END__
