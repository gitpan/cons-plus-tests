#! /usr/bin/env perl
#
#	Create a repository subdirectory with a .c file and Construct.
#	Invoke cons -R repository in a separate work subdirectory.
#	Check that the executable built correctly.  Check that an
#	immediate re-invocation doesn't build anything.  (Simultaneously
#	check that -Rrepository with no space works.)  Create a
#	new .c file in the work subdirectory; re-invoke cons -R
#	and check that the executable re-built correctly.  Re-invoke
#	immediately to check for no unnecessary rebuilt.  Update
#	the repository .c file; cons -R; check that it didn't
#	mistakenly pick up the updated repository file.  Remove
#	the work .c file; cons -R; check that it correctly built
#	with the updated repository file.
#

# $Id: t0106.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'single-module Program, -R');

$test->subdir('repository', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_foo = $test->catfile('work', 'foo');
$work_foo_c = $test->catfile('work', 'foo.c');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write(['repository', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository/foo.c\n");
	exit (0);
}
_EOF_


# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->write(['work', 'foo.c'], <<'_EOF_');
main()
{
	printf("work/foo.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->writable('repository', 1);

$test->write(['repository', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository/foo.c again\n");
	exit (0);
}
_EOF_

$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->unlink($work_foo_c);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

#
$test->pass;
__END__
