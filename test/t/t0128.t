#! /usr/bin/env perl
#
#	In the repository, define a single executable compiled from
#	three .c files in a source subdirectory.  One .c file has
#	a conditional #include for the selected OS.  Compilation
#	takes place in two separate build subdirectories with
#	separate Conscript files that establish 'Link' to the source
#	subdirectory and separate build environments.  Both Conscript
#	builds are invoked from the Construct file.  Build the two
#	executables in the repository.  Invoke cons in the work
#	subdirectory; nothing should get built (repository executables
#	are up-to-date).  Create a work copy of one of the .c files.
#	Invoke cons again in the work subdirectory; check that the
#	executables were constructed correctly and none of the
#	other .o files were created in the work directory.
#

# $Id: t0128.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'multiple-environment variant builds, -R, .c update');


#
$test->subdir('work',
		['work', 'src'],
		['work', 'build'],
		['work', 'build', 'foo'],
		['work', 'build', 'bar'],
		'repository',
		['repository', 'src'],
		['repository', 'build'],
		['repository', 'build', 'foo'],
		['repository', 'build', 'bar']);

#
$xxx_exe = "xxx$_exe";
$workpath_repository = $test->workpath('repository');
$repository_build_foo_src_xxx = $test->catfile('repository', 'build', 'foo', 'src', 'xxx');
$repository_build_bar_src_xxx = $test->catfile('repository', 'build', 'bar', 'src', 'xxx');
$work_build_foo_src_aaa_o = $test->catfile('work', 'build', 'foo', 'src', "aaa$_o");
$work_build_foo_src_bbb_o = $test->catfile('work', 'build', 'foo', 'src', "bbb$_o");
$work_build_foo_src_main_o = $test->catfile('work', 'build', 'foo', 'src', "main$_o");
$work_build_foo_src_xxx = $test->catfile('work', 'build', 'foo', 'src', 'xxx');
$work_build_foo_src_xxx_exe = $test->catfile('work', 'build', 'foo', 'src', $xxx_exe);
$work_build_bar_src_aaa_o = $test->catfile('work', 'build', 'bar', 'src', "aaa$_o");
$work_build_bar_src_bbb_o = $test->catfile('work', 'build', 'bar', 'src', "bbb$_o");
$work_build_bar_src_main_o = $test->catfile('work', 'build', 'bar', 'src', "main$_o");
$work_build_bar_src_xxx = $test->catfile('work', 'build', 'bar', 'src', 'xxx');
$work_build_bar_src_xxx_exe = $test->catfile('work', 'build', 'bar', 'src', $xxx_exe);

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
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	src/Conscript
);
_EOF_

$test->write(['repository', 'build', 'bar', 'Conscript'], <<_EOF_);
Link 'src' => '#src';

\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} = '-DBAR';
\$env = new cons ( \%env_hash );

Export qw( env );

Build qw(
	src/Conscript
);
_EOF_

$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
Import qw( env );
Program \$env '$xxx_exe', qw (
	aaa.c
	bbb.c
	main.c
);
_EOF_

$test->write(['repository', 'src', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("repository/src/aaa.c\n");
}
_EOF_

$test->write(['repository', 'src', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository/src/bbb.c\n");
}
_EOF_

$test->write(['repository', 'src', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
#ifdef	FOO
	printf("repository/src/main.c:  FOO\n");
#endif
#ifdef	BAR
	printf("repository/src/main.c:  BAR\n");
#endif
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_build_foo_src_xxx, stdout => <<_EOF_);
repository/src/aaa.c
repository/src/bbb.c
repository/src/main.c:  FOO
_EOF_

$test->execute(prog => $repository_build_bar_src_xxx, stdout => <<_EOF_);
repository/src/aaa.c
repository/src/bbb.c
repository/src/main.c:  BAR
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($work_build_foo_src_aaa_o);
$test->must_not_exist($work_build_foo_src_bbb_o);
$test->must_not_exist($work_build_foo_src_main_o);
$test->must_not_exist($work_build_foo_src_xxx_exe);
$test->must_not_exist($work_build_bar_src_aaa_o);
$test->must_not_exist($work_build_bar_src_bbb_o);
$test->must_not_exist($work_build_bar_src_main_o);
$test->must_not_exist($work_build_bar_src_xxx_exe);

$test->write(['work', 'src', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/src/bbb.c\n");
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo_src_xxx, stdout => <<_EOF_);
repository/src/aaa.c
work/src/bbb.c
repository/src/main.c:  FOO
_EOF_

$test->execute(prog => $work_build_bar_src_xxx, stdout => <<_EOF_);
repository/src/aaa.c
work/src/bbb.c
repository/src/main.c:  BAR
_EOF_
$test->must_not_exist($work_build_foo_src_aaa_o);
$test->must_not_exist($work_build_foo_src_main_o);
$test->must_not_exist($work_build_bar_src_aaa_o);
$test->must_not_exist($work_build_bar_src_main_o);

#
$test->pass;
__END__
