#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in a
#	repository src subdirectory.   Compilation takes place in
#	a separate local build subdirectory established via the
#	'Link' command, pulling the .c files directly from the
#	repository subdirectory.  Create a .c file in the work src
#	subdirectory.  Re-compile to pick up the local .c file in
#	the build subdirectory.
#

# $Id: t0125.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Link update, -R');

$test->subdir('work',
		['work', 'src'],
		'repository',
		['repository', 'src']);

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_build_foo = $test->catfile('work', 'build', 'foo');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<'_EOF_');
Link 'build' => 'src';
Build qw(
	build/Conscript
);
_EOF_

$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
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
	printf("repository/src/main.c\n");
	exit (0);
}
_EOF_


#
# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);


$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo, stdout => <<_EOF_);
repository/src/aaa.c
repository/src/bbb.c
repository/src/main.c
_EOF_

# Theoretically, sleep(1) should be sufficient to ensure a newer time.
# Empirically, that sometimes fails on Windows NT, whereas sleep(2)
# always seems to work as we want.  Don't fight city hall.
$test->sleep(2);	# ENSURE TIME IS NEWER

$test->write(['work', 'src', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/src/bbb.c\n");
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_build_foo, stdout => <<_EOF_);
repository/src/aaa.c
work/src/bbb.c
repository/src/main.c
_EOF_

#
$test->pass;
__END__
