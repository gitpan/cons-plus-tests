#! /usr/bin/env perl
#
#	Create a work subdirectory and a repository subdirectory.
#	The repository contains a single .c file.  The work
#	subdirectory contains the Construct file with Repository
#	pointing to the repository.  Invoke cons in the work
#	subdirectory.  Check to make sure the executable was
#	generated correctly from the repository .c file.
#

# $Id: t0102.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'single-module Repository Program');

$test->subdir('repository', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_foo = $test->catfile('work', 'foo');
$work_foo_c = $test->catfile('work', 'foo.c');
$repository_foo_c = $test->catfile('repository', 'foo.c');

#
$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository '$workpath_repository';
Program \$env '$foo_exe', 'foo.c';
_EOF_


$test->write($repository_foo_c, <<'_EOF_');
main()
{
	printf("repository/foo.c\n");
	exit (0);
}
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write($work_foo_c, <<'_EOF_');
main()
{
	printf("work/foo.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->writable($repository_foo_c, 1);

$test->write($repository_foo_c, <<'_EOF_');
main()
{
	printf("repository/foo.c again\n");
	exit (0);
}
_EOF_

$test->writable($repository_foo_c, 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_foo_c);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
