#! /usr/bin/env perl
#
#	Create a repository directory with four .c files and a
#	Construct file pointing to the Repository.  Build the
#	executable in the repository directory.  "Lock" the repository
#	directory by removing all write permissions.  Copy the
#	Construct file to the work directory.  Invoke cons in the
#	work subdirectory.  check that it didn't re-build the
#	executable (the repository binary is up-to-date).  Create
#	a work .c file; invoke cons in the work subdirectory; check
#	that the executable re-built in the work subdirectory with
#	the work .c file.  Remove the work .c file; cons; check
#	that the executable re-built in the work directory with
#	the repository .c file again.  Re-build in the repository
#	to check that nothing there re-builds.
#

# $Id: t0114.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Repository link with .o from repository');

$test->subdir('repository', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$repository_Construct = $test->catfile('repository', 'Construct');
$repository_foo = $test->catfile('repository', 'foo');
$work_Construct = $test->catfile('work', 'Construct');
$work_foo = $test->catfile('work', 'foo');
$work_aaa_o = $test->catfile('work', 'aaa$_o');
$work_bbb_c = $test->catfile('work', 'bbb.c');
$work_ccc_o = $test->catfile('work', 'ccc$_o');
$work_main_o = $test->catfile('work', 'main$_o');

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository '$workpath_repository';
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	ccc.c
	main.c
);
_EOF_

$test->write(['repository', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("repository/aaa.c\n");
}
_EOF_

$test->write(['repository', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository/bbb.c\n");
}
_EOF_

$test->write(['repository', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("repository/ccc.c\n");
}
_EOF_

$test->write(['repository', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	ccc();
	printf("repository/main.c\n");
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'repository', targets => ".");

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

#
# "Check out" the Construct file.
$test->copy($repository_Construct, $work_Construct);

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write(['work', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/bbb.c\n");
}
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
work/bbb.c
repository/ccc.c
repository/main.c
_EOF_
$test->must_not_exist($work_aaa_o);
$test->must_not_exist($work_ccc_o);
$test->must_not_exist($work_main_o);

$test->unlink($work_bbb_c);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/ccc.c
repository/main.c
_EOF_

# Make the repository writable again.
$test->writable('repository', 1);

$test->up_to_date('chdir' => 'repository', targets => ".");

#
$test->pass;
__END__
