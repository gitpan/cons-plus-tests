#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in a source
#	subdirectory.  One .c file has a conditional #include for
#	the selected OS.  Compilation takes place in two separate
#	build subdirectories with separate Conscript files that
#	establish 'Link' to the source subdirectory and separate
#	build environments.  Both Conscript builds are invoked from
#	the same invocation of Cons.
#

# $Id: t0019.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'multiple-environment variant builds');

$test->subdir('src', 'build', ['build', 'foo'], ['build', 'bar']);

#
$xxx_exe = "xxx$_exe";
$build_foo_Conscript = $test->catfile('build', 'foo', 'Conscript');
$build_foo_src_xxx = $test->catfile('build', 'foo', 'src', 'xxx');
$build_bar_Conscript = $test->catfile('build', 'bar', 'Conscript');
$build_bar_src_xxx = $test->catfile('build', 'bar', 'src', 'xxx');
$src_Conscript = $test->catfile('src', 'Conscript');

#
$test->write('Construct', <<_EOF_);
Build qw(
	$build_foo_Conscript
	$build_bar_Conscript
);
_EOF_

$test->write($build_foo_Conscript, <<_EOF_);
Link 'src' => '#src';

\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} .= ' -DFOO';
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	$src_Conscript
);
_EOF_

$test->write($build_bar_Conscript, <<_EOF_);
Link 'src' => '#src';

\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} .= ' -DBAR';
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	$src_Conscript
);
_EOF_

$test->write($src_Conscript, <<_EOF_);
Import qw( env );
Program \$env '$xxx_exe', qw (
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
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
#ifdef	FOO
	printf("FOO!\n");
#endif
#ifdef	BAR
	printf("BAR!\n");
#endif
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => $build_foo_src_xxx, stdout => <<_EOF_);
src/aaa.c
src/bbb.c
FOO!
_EOF_

$test->execute(prog => $build_bar_src_xxx, stdout => <<_EOF_);
src/aaa.c
src/bbb.c
BAR!
_EOF_


#
$test->pass;
__END__
