#! /usr/bin/env perl
#
#	Compile a single executable in a subdirectory from two .c
#	files.  The executable prints a string supplied (through
#	a #define) by a STRING= argument to the invoking cons
#	command line.
#

# $Id: t0008.t,v 1.3 2000/06/01 22:00:44 knight Exp $

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
use File::Spec;

$test = Test::Cmd::Cons->new(string => '$ARG{}');

$test->subdir('src');

#
$foo_exe = "foo$_exe";
$src_Conscript = $test->catfile('src', 'Conscript');
$src_foo = $test->catfile('src', 'foo');

#
$test->write("Construct", <<_EOF_);
\$print = \$ARG{STRING};
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} .= " -DFOO=\\\\\\\"\$print\\\\\\\"";
\$env = new cons ( \%env_hash );
Export qw( env );
Build qw(
	$src_Conscript
);
_EOF_

$test->write($src_Conscript, <<_EOF_);
Import qw( env );
Program \$env '$foo_exe', qw(
	aaa.c
	main.c
);
_EOF_

$test->write(['src', 'aaa.c'], <<'_EOF_');
void
aaa(void)
{
	printf("src/aaa.c\n");
}
_EOF_

$test->write(['src', 'main.c'], <<'_EOF_');
extern void aaa(void);
int
main(int argc, char *argv[])
{
	aaa();
	printf("%s!\n", FOO);
	exit (0);
}
_EOF_

#
$test->run(flags => "STRING=antidisestablishmentarianism", targets => ".");

$test->execute(prog => $src_foo, stdout => <<_EOF_);
src/aaa.c
antidisestablishmentarianism!
_EOF_

$test->pass;
__END__
