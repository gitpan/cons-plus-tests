#! /usr/bin/env perl
#
#	In the repository, define a single executable compiled from
#	three .c files in a source subdirectory.  One module has
#	a conditional #include for the selected OS.  Compilation
#	takes place in two separate build subdirectories established
#	via the 'Link' command in two separate invocations of cons.
#	The appropriate build directory is specified via "OS=" on
#	the cons command line.  Build one OS in the repository.
#	Invoke cons for the same OS in the work subdirectory;
#	nothing should get built.  Invoke cons for the second OS
#	in the work subdirectory, check that it built properly.
#	Update a .h file in the work subdirectory and re-build the
#	second OS; make sure it picked up the new .h file.  Invoke
#	cons for the first OS in the work subdirectory; check that
#	it built correctly.
#

# $Id: t0127.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'single-environment variant builds, -R');

$test->subdir('work',
		['work', 'src'],
		'repository',
		['repository', 'src']);

#
$xxx_exe = "xxx$_exe";
$workpath_repository = $test->workpath('repository');
$repository_build_foo_xxx = $test->catfile('repository', 'build', 'foo', 'xxx');
$work_build_bar_xxx = $test->catfile('work', 'build', 'bar', 'xxx');
$work_build_foo_aaa_o = $test->catfile('work', 'build', 'foo', 'aaa$_o');
$work_build_foo_bbb_o = $test->catfile('work', 'build', 'foo', 'aaa$_o');
$work_build_foo_main_o = $test->catfile('work', 'build', 'foo', 'aaa$_o');
$work_build_foo_xxx = $test->catfile('work', 'build', 'foo', 'xxx');
$work_build_foo_xxx_exe = $test->catfile('work', 'build', 'foo', $xxx_exe);

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
die qq(OS must be specified) unless \$OS = \$ARG{OS};
\$BUILD = "#build/\$OS";
%cflags = (
	'foo'	=> '-DFOO',
	'bar'	=> '-DBAR',
);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} = \$cflags{\$OS};
\$env = new cons ( \%env_hash );
Export ( env );
Link \$BUILD => 'src';
Build (
	"\$BUILD/Conscript"
);
_EOF_
$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
Import ( env );
\$my_env = \$env->clone(
	CPPPATH => 'src',
);
Program \$my_env '$xxx_exe', qw (
	aaa.c
	bbb.c
	main.c
);
_EOF_

$test->write(['repository', 'src', 'string.h'], <<'_EOF_');
#ifdef	FOO
#define	STRING	"REPOSITORY_FOO"
#endif
#ifdef	BAR
#define	STRING	"REPOSITORY_BAR"
#endif
_EOF_

$test->write(['repository', 'src', 'aaa.c'], <<'_EOF_');
#include <string.h>
aaa()
{
	printf("repository/src/aaa.c:  %s\n", STRING);
}
_EOF_

$test->write(['repository', 'src', 'bbb.c'], <<'_EOF_');
#include <string.h>
bbb()
{
	printf("repository/src/bbb.c:  %s\n", STRING);
}
_EOF_

$test->write(['repository', 'src', 'main.c'], <<'_EOF_');
#include <string.h>
main()
{
#ifdef	BAR
	printf("Only when #define BAR\n");
#endif
	aaa();
	bbb();
	printf("repository/src/main.c:  %s\n", STRING);
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', flags => "OS=foo", targets => ".");

$test->execute(prog => $repository_build_foo_xxx, stdout => <<_EOF_);
repository/src/aaa.c:  REPOSITORY_FOO
repository/src/bbb.c:  REPOSITORY_FOO
repository/src/main.c:  REPOSITORY_FOO
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => "$flags OS=foo", targets => ".");
$test->must_not_exist($work_build_foo_aaa_o);
$test->must_not_exist($work_build_foo_bbb_o);
$test->must_not_exist($work_build_foo_main_o);
$test->must_not_exist($work_build_foo_xxx_exe);

$test->run('chdir' => 'work', flags => "$flags OS=bar", targets => ".");

$test->execute(prog => $work_build_bar_xxx, stdout => <<_EOF_);
Only when #define BAR
repository/src/aaa.c:  REPOSITORY_BAR
repository/src/bbb.c:  REPOSITORY_BAR
repository/src/main.c:  REPOSITORY_BAR
_EOF_

$test->write(['work', 'src', 'string.h'], <<'_EOF_');
#ifdef	FOO
#define	STRING	"WORK_FOO"
#endif
#ifdef	BAR
#define	STRING	"WORK_BAR"
#endif
_EOF_

$test->run('chdir' => 'work', flags => "$flags OS=bar", targets => ".");

$test->execute(prog => $work_build_bar_xxx, stdout => <<_EOF_);
Only when #define BAR
repository/src/aaa.c:  WORK_BAR
repository/src/bbb.c:  WORK_BAR
repository/src/main.c:  WORK_BAR
_EOF_

$test->run('chdir' => 'work', flags => "$flags OS=foo", targets => ".");

$test->execute(prog => $work_build_foo_xxx, stdout => <<_EOF_);
repository/src/aaa.c:  WORK_FOO
repository/src/bbb.c:  WORK_FOO
repository/src/main.c:  WORK_FOO
_EOF_

#
$test->pass;
__END__
