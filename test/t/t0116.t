#! /usr/bin/env perl
#
#	Create a repository directory and a work directory.  The
#	repository contains two subdirectories, one with two
#	.c files and one with one .c file.  The Conscript file
#	specifies the separate .c file with a top-level (#) file
#	name.
#

# $Id: t0116.t,v 1.4 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'top-level (#) path name, -R');


$test->subdir('work',
		'repository',
		['repository', 'src'],
		['repository', 'xxx']);

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_src_foo = $test->catfile('work', 'src', 'foo');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<'_EOF_');
Build qw(
	src/Conscript
);
_EOF_

$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
	aaa.c
	#xxx/aaa.c
	main.c
);
_EOF_

$test->write(['repository', 'src', 'aaa.c'], <<'_EOF_');
src_a()
{
	printf("repository/src/aaa.c\n");
}
_EOF_

$test->write(['repository', 'xxx', 'aaa.c'], <<'_EOF_');
xxx_a()
{
	printf("repository/xxx/aaa.c\n");
}
_EOF_

$test->write(['repository', 'src', 'main.c'], <<'_EOF_');
main()
{
	src_a();
	xxx_a();
	printf("repository/src/main.c\n");
	exit (0);
}
_EOF_


# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_src_foo, stdout => <<_EOF_);
repository/src/aaa.c
repository/xxx/aaa.c
repository/src/main.c
_EOF_

#
$test->pass;
__END__
