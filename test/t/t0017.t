#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in a
#	subdirectory.   Compilation takes place in a separate build
#	subdirectory established via the 'Link' command.
#

# $Id: t0017.t,v 1.3 2000/06/01 22:00:44 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Link');

$test->subdir('src');

#
$foo_exe = "foo$_exe";
$build_Conscript = $test->catfile('build', 'Conscript');
$build_foo = $test->catfile('build', 'foo');
$src_Conscript = $test->catfile('src', 'Conscript');

#
$test->write('Construct', <<_EOF_);
Link 'build' => 'src';
Build qw(
	$build_Conscript
);
_EOF_

$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
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

$test->write(['src', 'bbb.c'], <<'_EOF_');
void
bbb(void)
{
	printf("src/bbb.c\n");
}
_EOF_

$test->write(['src', 'main.c'], <<'_EOF_');
extern void aaa(void);
extern void bbb(void);
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
	printf("SUCCESS!\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => $build_foo, stdout => <<_EOF_);
src/aaa.c
src/bbb.c
SUCCESS!
_EOF_

#
$test->pass;
__END__
