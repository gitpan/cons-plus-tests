#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in a source
#	subdirectory.  One module has a conditional #include for
#	the selected OS.  Compilation takes place in two separate
#	build subdirectories established via the 'Link' command in
#	two separate invocations of cons.  The appropriate build
#	directory is specified via "OS=" on the cons command line.
#

# $Id: t0018.t,v 1.3 2000/06/01 22:00:44 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'single-environment variant builds');

$test->subdir('src');

#
$xxx_exe = "xxx$_exe";
$build_foo_xxx = $test->catfile('build', 'foo', 'xxx');
$build_bar_xxx = $test->catfile('build', 'bar', 'xxx');

#
$test->write('Construct', <<_EOF_);
die qq(OS must be specified) unless \$OS = \$ARG{OS};
\$BUILD = "#build/\$OS";
%cflags = (
	'foo'	=> '-DFOO',
	'bar'	=> '-DBAR',
);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} .= " \$cflags{\$OS}";
\$env = new cons ( \%env_hash );
Export ( env );
Link \$BUILD => 'src';
Build (
	"\$BUILD/Conscript"
);
_EOF_

$test->write(['src', 'Conscript'], <<_EOF_);
Import ( env );
Program \$env '$xxx_exe', qw (
	aaa.c
	bbb.c
	main.c
);
_EOF_

$test->write(['src', 'string.h'], <<'_EOF_');
#ifdef	FOO
#define	STRING	"FOO"
#endif
#ifdef	BAR
#define	STRING	"BAR"
#endif
_EOF_

$test->write(['src', 'aaa.c'], <<'_EOF_');
#include "string.h"
void
aaa(void)
{
	printf("src/aaa.c:  %s\n", STRING);
}
_EOF_

$test->write(['src', 'bbb.c'], <<'_EOF_');
#include "string.h"
void
bbb(void)
{
	printf("src/bbb.c:  %s\n", STRING);
}
_EOF_

$test->write(['src', 'main.c'], <<'_EOF_');
#include "string.h"
extern void aaa(void);
extern void bbb(void);
int
main(int argc, char *argv[])
{
#ifdef	BAR
	printf("Only when BAR:\n");
#endif
	aaa();
	bbb();
	printf("%s!\n", STRING);
	exit (0);
}
_EOF_

#
$test->run(flags => "OS=foo", targets => ".");

$test->execute(prog => $build_foo_xxx, stdout => <<_EOF_);
src/aaa.c:  FOO
src/bbb.c:  FOO
FOO!
_EOF_

#
$test->run(flags => "OS=bar", targets => ".");

$test->execute(prog => $build_bar_xxx, stdout => <<_EOF_);
Only when BAR:
src/aaa.c:  BAR
src/bbb.c:  BAR
BAR!
_EOF_

#
$test->pass;
__END__
