#! /usr/bin/env perl
#
#	Create a work subdirectory and a repository subdirectory.
#	The repository contains four .c files to build into an
#	executable and a Construct file.  Invoke cons -R in the
#	work subdirectory; check that the executable was built
#	correctly from repository .c files.  Create a work subdirectory
#	copy of one of the .c files; invoke cons -R; check that
#	the executable uses the one work .c files and the rest from
#	the repository.  Create work copies of the remaining .c
#	files; cons -R; check that the executable uses all the work
#	.c files.  Remove one work .c files; cons -R; check that
#	the executable uses the repository .c file for the one
#	removed.  Remove the rest of the work .c files; cons -R;
#	check that the executable uses all the repository .c files.
#

# $Id: t0108.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'multi-module Program, -R');

$test->subdir('repository', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_foo = $test->catfile('work', 'foo');
$work_aaa_c = $test->catfile('work', 'aaa.c');
$work_bbb_c = $test->catfile('work', 'bbb.c');
$work_ccc_c = $test->catfile('work', 'ccc.c');
$work_main_c = $test->catfile('work', 'main.c');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
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


# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->write(['work', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/bbb.c\n");
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
work/bbb.c
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->write(['work', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("work/aaa.c\n");
}
_EOF_

$test->write(['work', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("work/ccc.c\n");
}
_EOF_

$test->write(['work', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	ccc();
	printf("work/main.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/aaa.c
work/bbb.c
work/ccc.c
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->unlink($work_ccc_c);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/aaa.c
work/bbb.c
repository/ccc.c
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->unlink($work_aaa_c);

$test->unlink($work_bbb_c);

$test->unlink($work_main_c);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

#
$test->pass;
__END__
