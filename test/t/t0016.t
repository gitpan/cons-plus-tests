#! /usr/bin/env perl
#
#	Compile a single executable from four .c files in the local
#	directory.  Each .c file includes one of two .h files from
#	a subdirectory.  Update one of the two .h files and re-compile
#	to make sure the right .o files get re-generated.
#

# $Id: t0016.t,v 1.3 2000/06/01 22:00:44 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'selective #include <...> update');

$test->subdir('include');

#
$foo_exe = "foo$_exe";

#
$test->write('Construct', <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = '.';
\$env = new cons ( \%env_hash );
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	ccc.c
	main.c
);
_EOF_

$test->write(['include', 'foo.h'], <<'_EOF_');
#define	STRING	"FOO"
_EOF_

$test->write(['include', 'bar.h'], <<'_EOF_');
#define	STRING	"BAR"
_EOF_


$test->write(['include', 'aaa.h'], <<'_EOF_');
#include <include/foo.h>
_EOF_

$test->write('aaa.c', <<'_EOF_');
#include <include/aaa.h>
void
aaa(void)
{
	printf("aaa.c:  %s\n", STRING);
}
_EOF_

$test->write(['include', 'bbb.h'], <<'_EOF_');
#include <include/bar.h>
_EOF_

$test->write('bbb.c', <<'_EOF_');
#include <include/bbb.h>
void
bbb(void)
{
	printf("bbb.c:  %s\n", STRING);
}
_EOF_

$test->write(['include', 'ccc.h'], <<'_EOF_');
#include <include/bar.h>
_EOF_

$test->write('ccc.c', <<'_EOF_');
#include <include/ccc.h>
void
ccc(void)
{
	printf("ccc.c:  %s\n", STRING);
}
_EOF_

$test->write('main.c', <<'_EOF_');
extern void aaa(void);
extern void bbb(void);
extern void ccc(void);
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
	ccc();
	printf("SUCCESS!\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
aaa.c:  FOO
bbb.c:  BAR
ccc.c:  BAR
SUCCESS!
_EOF_

$test->write(['include', 'bbb.h'], <<'_EOF_');
#include <include/foo.h>
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
aaa.c:  FOO
bbb.c:  FOO
ccc.c:  BAR
SUCCESS!
_EOF_

$test->write(['include', 'foo.h'], <<'_EOF_');
#define	STRING	"NEW"
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
aaa.c:  NEW
bbb.c:  NEW
ccc.c:  BAR
SUCCESS!
_EOF_

#
$test->pass;
__END__
