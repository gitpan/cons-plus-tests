#! /usr/bin/env perl
#
#	Create an executable from a .c file in the repository.
#	Build in a work subdirectory; everything is up-to-date.
#	Create a work Construct file that specifies the executable
#	is Local.  Build; the repository executable should be copied
#	into the work directory.  Create a work .c file; build;
#	the work executable should be updated.
#

# $Id: t0142.t,v 1.5 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Local');

$test->subdir('work', 'repository');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$workpath_repository_foo = $test->workpath('repository', 'foo');
$workpath_work_foo = $test->workpath('work', 'foo');
$workpath_work_foo_o = $test->workpath('work', "foo$_o");
$workpath_work_foo_exe = $test->workpath('work', "foo$_exe");

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write(['repository', 'foo.c'], <<'_EOF_');
main(int argc, char *argv[])
{
	printf("repository/foo.c called with arg 0 = '%s'\n", *argv);
	exit (0);
}
_EOF_


$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $workpath_repository_foo, stdout => <<_EOF_);
repository/foo.c called with arg 0 = '\Q$workpath_repository_foo\E'
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($workpath_work_foo_o);
$test->must_not_exist($workpath_work_foo_exe);

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
Local '$foo_exe';
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $workpath_work_foo, stdout => <<_EOF_);
repository/foo.c called with arg 0 = '\Q$workpath_work_foo\E'
_EOF_
$test->must_not_exist($workpath_work_foo_o);

$test->write(['work', 'foo.c'], <<'_EOF_');
main(int argc, char *argv[])
{
	printf("work/foo.c called with arg 0 = '%s'\n", *argv);
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $workpath_work_foo, stdout => <<_EOF_);
work/foo.c called with arg 0 = '\Q$workpath_work_foo\E'
_EOF_

#
$test->pass;
__END__
