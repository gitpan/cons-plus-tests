#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in a
#	subdirectory with UseCache.  Execute cons again, making
#	sure nothing was recompiled.  Execute cons -r to remove
#	generated files from the subdirectory.  Execute cons again,
#	checking the output to make sure that the generated files
#	were retrieved from the cache.  Cons -r again to remove
#	files.  Execute cons -cd, checking output to make sure that
#	Cons reports caching is disabled and that files were built
#	normally.
#
#	NOTE:  THIS TEST EXAMINES THE ACTIONS USED TO BUILD FILES.
#

# $Id: t0042.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons qw($_exe $_o);

$test = Test::Cmd::Cons->new(string => 'UseCache, -cd');

$test->subdir('cache', 'src');

$CC = $test->cons_env_val('CC') || 'cc';
$LINK = $test->cons_env_val('LINK') || $CC;

#
$aaa_o = "aaa$_o";
$bbb_o = "bbb$_o";
$main_o = "main$_o";
$foo_exe = "foo$_exe";
$src_foo = $test->catfile('src', 'foo');

#
$test->write(['src', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	main.c
);
UseCache 'cache';
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
	printf("src/main.c\n");
	exit (0);
}
_EOF_

#
$test->run('chdir' => 'src', targets => ".");

$test->execute(prog => $src_foo, stdout => <<_EOF_);
src/aaa.c
src/bbb.c
src/main.c
_EOF_

#
$test->up_to_date('chdir' => 'src', targets => ".");

#
$test->run('chdir' => 'src', flags => "-r", targets => ".");

#
$test->run('chdir' => 'src', targets => ".", stdout => <<_EOF_, stderr => '');
Retrieved $aaa_o from cache
Retrieved $bbb_o from cache
Retrieved $main_o from cache
Retrieved $foo_exe from cache
_EOF_

#
$test->run('chdir' => 'src', flags => "-r", targets => ".");

#
$test->run('chdir' => 'src', flags => "-cd", targets => ".", stdout => <<_EOF_, stderr => "Note: caching disabled by -cd flag\n");
$CC .*\\b\Qaaa.c\E\\b.*\Q$aaa_o\E\\b.*
$CC .*\\b\Qbbb.c\E\\b.*\Q$bbb_o\E\\b.*
$CC .*\\b\Qmain.c\E\\b.*\Q$main_o\E\\b.*
$LINK .*\Q$foo_exe\E\\b.*\\b\Q$aaa_o $bbb_o $main_o\E\\b.*
_EOF_

#
$test->pass;
__END__
