#! /usr/bin/env perl
#
#	Create a repository directory and a work directory, with
#	a src directory under each.  The repository/src directory
#	contains three .c files and a Conscript file.  The work
#	Construct file Builds the Conscript file and Repository
#	points to the repository.  Invoke cons in the work
#	subdirectory.  Check that it built the executable in the
#	src subdirectory, correctly picking up the files from the
#	repository.  Build again; check that nothing is rebuilt.
#

# $Id: t0115.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Repository Build');

#
$test->subdir('work',
		['work', 'src'],
		'repository',
		['repository', 'src']);

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_src_foo = $test->catfile('work', 'src', 'foo');

#
$test->write(['work', 'Construct'], <<_EOF_);
Repository '$workpath_repository';
Build qw(
	src/Conscript
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

#
$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_src_foo, stdout => <<_EOF_);
repository/src/aaa.c
repository/src/bbb.c
repository/src/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
