#! /usr/bin/env perl
#
#	In a repository, create xxx and include subdirectories in
#	a src subdirectory, and a build subdirectory with separate
#	subdirectores for two variant "OS" builds.  CPPPATH in the
#	repository Construct file specifies src/xxx:src/include.
#	A .c file in the xxx subdirectory #includes a .h file in
#	the xxx subdirectory, which nested #includes a .h file in
#	the include subdirectory.  Build in the repository.  Build
#	in the work directory; everything should still be up-to-date.
#	Create a work copy of the include subdirectory .h file;
#	build.  Create a work copy of the xxx subdirectory .h file;
#	build.  Remove the work copy of the include subdirectory
#	.h file; build.
#

# $Id: t0130.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'multi-environment variant builds, -R, multi-dir .h');


#
$test->subdir('work',
		['work', 'src'],
		['work', 'src', 'include'],
		['work', 'src', 'xxx'],
		['work', 'build'],
		['work', 'build', 'foo'],
		['work', 'build', 'bar'],
		'repository',
		['repository', 'src'],
		['repository', 'src', 'include'],
		['repository', 'src', 'xxx'],
		['repository', 'build'],
		['repository', 'build', 'foo'],
		['repository', 'build', 'bar']);


#
$xxx_exe = "xxx$_exe";
$workpath_repository = $test->workpath('repository');
$repository_build_foo_src_xxx_xxx = $test->catfile('repository', 'build', 'foo', 'src', 'xxx', 'xxx');
$repository_build_bar_src_xxx_xxx = $test->catfile('repository', 'build', 'bar', 'src', 'xxx', 'xxx');
$work_build_foo_src_xxx_aaa_o = $test->catfile('work', 'build', 'foo', 'src', 'xxx', "aaa$_o");
$work_build_foo_src_xxx_bbb_o = $test->catfile('work', 'build', 'foo', 'src', 'xxx', "bbb$_o");
$work_build_foo_src_xxx_main_o = $test->catfile('work', 'build', 'foo', 'src', 'xxx', "main$_o");
$work_build_foo_src_xxx_xxx = $test->catfile('work', 'build', 'foo', 'src', 'xxx', 'xxx');
$work_build_foo_src_xxx_xxx_exe = $test->catfile('work', 'build', 'foo', 'src', 'xxx', $xxx_exe);
$work_build_bar_src_xxx_aaa_o = $test->catfile('work', 'build', 'bar', 'src', 'xxx', "aaa$_o");
$work_build_bar_src_xxx_bbb_o = $test->catfile('work', 'build', 'bar', 'src', 'xxx', "bbb$_o");
$work_build_bar_src_xxx_main_o = $test->catfile('work', 'build', 'bar', 'src', 'xxx', "main$_o");
$work_build_bar_src_xxx_xxx = $test->catfile('work', 'build', 'bar', 'src', 'xxx', 'xxx');
$work_build_bar_src_xxx_xxx_exe = $test->catfile('work', 'build', 'bar', 'src', 'xxx', $xxx_exe);
$work_src_include_my_string_h = $test->catfile('work', 'src', 'include', 'my_string.h');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<'_EOF_');
Build qw(
	build/foo/Conscript
	build/bar/Conscript
);
_EOF_

$test->write(['repository', 'build', 'foo', 'Conscript'], <<_EOF_);
Link 'src' => '#src';

\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} = '-DFOO';
\$env_hash{CPPPATH} = ['src/xxx', 'src/include'];
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	src/xxx/Conscript
);
_EOF_

$test->write(['repository', 'build', 'bar', 'Conscript'], <<_EOF_);
Link 'src' => '#src';

\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} = '-DBAR';
\$env_hash{CPPPATH} = ['src/xxx', 'src/include'];
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	src/xxx/Conscript
);
_EOF_

$test->write(['repository', 'src', 'xxx', 'Conscript'], <<_EOF_);
Import qw( env );
Program \$env '$xxx_exe', qw (
	main.c
);
_EOF_

$test->write(['repository', 'src', 'include', 'my_string.h'], <<'_EOF_');
#ifdef	FOO
#define	INCLUDE_OS	"FOO"
#endif
#ifdef	BAR
#define	INCLUDE_OS	"BAR"
#endif
#define	INCLUDE_STRING	"repository/src/include/my_string.h:  %s\n"
_EOF_

$test->write(['repository', 'src', 'xxx', 'include.h'], <<'_EOF_');
#include <my_string.h>
#ifdef	FOO
#define	XXX_OS		"FOO"
#endif
#ifdef	BAR
#define	XXX_OS		"BAR"
#endif
#define	XXX_STRING	"repository/src/xxx/include.h:  %s\n"
_EOF_

$test->write(['repository', 'src', 'xxx', 'main.c'], <<'_EOF_');
#include <include.h>
#ifdef	FOO
#define	MAIN_OS		"FOO"
#endif
#ifdef	BAR
#define	MAIN_OS		"BAR"
#endif
main()
{
	printf(INCLUDE_STRING, INCLUDE_OS);
	printf(XXX_STRING, XXX_OS);
	printf("repository/src/xxx/main.c:  %s\n", MAIN_OS);
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_build_foo_src_xxx_xxx, stdout => <<_EOF_);
repository/src/include/my_string.h:  FOO
repository/src/xxx/include.h:  FOO
repository/src/xxx/main.c:  FOO
_EOF_

$test->execute(prog => $repository_build_bar_src_xxx_xxx, stdout => <<_EOF_);
repository/src/include/my_string.h:  BAR
repository/src/xxx/include.h:  BAR
repository/src/xxx/main.c:  BAR
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($work_build_foo_src_xxx_aaa_o);
$test->must_not_exist($work_build_foo_src_xxx_bbb_o);
$test->must_not_exist($work_build_foo_src_xxx_main_o);
$test->must_not_exist($work_build_foo_src_xxx_xxx_exe);
$test->must_not_exist($work_build_bar_src_xxx_aaa_o);
$test->must_not_exist($work_build_bar_src_xxx_bbb_o);
$test->must_not_exist($work_build_bar_src_xxx_main_o);
$test->must_not_exist($work_build_bar_src_xxx_xxx_exe);

# Theoretically, sleep(1) should be sufficient to ensure a newer time.
# Empirically, that sometimes fails on Windows NT, whereas sleep(2)
# always seems to work as we want.  Don't fight city hall.
$test->sleep(2);	# ENSURE TIME IS NEWER

$test->write(['work', 'src', 'include', 'my_string.h'], <<'_EOF_');
#ifdef	FOO
#define	INCLUDE_OS	"FOO"
#endif
#ifdef	BAR
#define	INCLUDE_OS	"BAR"
#endif
#define	INCLUDE_STRING	"work/src/include/my_string.h:  %s\n"
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo_src_xxx_xxx, stdout => <<_EOF_);
work/src/include/my_string.h:  FOO
repository/src/xxx/include.h:  FOO
repository/src/xxx/main.c:  FOO
_EOF_

$test->execute(prog => $work_build_bar_src_xxx_xxx, stdout => <<_EOF_);
work/src/include/my_string.h:  BAR
repository/src/xxx/include.h:  BAR
repository/src/xxx/main.c:  BAR
_EOF_

$test->sleep(2);	# ENSURE TIME IS NEWER

$test->write(['work', 'src', 'xxx', 'include.h'], <<'_EOF_');
#include <my_string.h>
#ifdef	FOO
#define	XXX_OS		"FOO"
#endif
#ifdef	BAR
#define	XXX_OS		"BAR"
#endif
#define	XXX_STRING	"work/src/xxx/include.h:  %s\n"
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo_src_xxx_xxx, stdout => <<_EOF_);
work/src/include/my_string.h:  FOO
work/src/xxx/include.h:  FOO
repository/src/xxx/main.c:  FOO
_EOF_

$test->execute(prog => $work_build_bar_src_xxx_xxx, stdout => <<_EOF_);
work/src/include/my_string.h:  BAR
work/src/xxx/include.h:  BAR
repository/src/xxx/main.c:  BAR
_EOF_

$test->unlink($work_src_include_my_string_h);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo_src_xxx_xxx, stdout => <<_EOF_);
repository/src/include/my_string.h:  FOO
work/src/xxx/include.h:  FOO
repository/src/xxx/main.c:  FOO
_EOF_

$test->execute(prog => $work_build_bar_src_xxx_xxx, stdout => <<_EOF_);
repository/src/include/my_string.h:  BAR
work/src/xxx/include.h:  BAR
repository/src/xxx/main.c:  BAR
_EOF_

#
$test->pass;
__END__
