#! /usr/bin/env perl
#
#	In a repository subdirectory, create Construct and Conscript
#	files for creating four executables, two from
#	.c files in the local directory and two from .c files in a
#	subdirectory.  In the work subdirectory, invoke cons -R to
#	build .o files and executables from these source files.
#	Invoke cons in the repository build repository .o and
#	executable files.  In the work subdirectory, remove one of
#	the local executables and .o file using -r.  Remove the
#	executables and .o files from the subdirectory using -r.
#	Remove the rest of the executables and .o files using -r.
#

# $Id: t0135.t,v 1.5 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => '-r, -R');

$test->subdir('work', 'repository', ['repository', 'subdir']);

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$workpath_repository = $test->workpath('repository');
$repository_aaa = $test->catfile('repository', 'aaa');
$repository_bbb = $test->catfile('repository', 'bbb');
$repository_subdir_ccc = $test->catfile('repository', 'subdir', 'ccc');
$repository_subdir_ddd = $test->catfile('repository', 'subdir', 'ddd');
$work_aaa = $test->catfile('work', 'aaa');
$work_bbb = $test->catfile('work', 'bbb');
$work_subdir_ccc = $test->catfile('work', 'subdir', 'ccc');
$work_subdir_ddd = $test->catfile('work', 'subdir', 'ddd');
$work_aaa_o = $test->catfile('work', "aaa$_o");
$work_bbb_o = $test->catfile('work', "bbb$_o");
$work_subdir_ccc_o = $test->catfile('work', 'subdir', "ccc$_o");
$work_subdir_ddd_o = $test->catfile('work', 'subdir', "ddd$_o");
$work_aaa_exe = $test->catfile('work', "aaa$_exe");
$work_bbb_exe = $test->catfile('work', "bbb$_exe");
$work_subdir_ccc_exe = $test->catfile('work', 'subdir', "ccc$_exe");
$work_subdir_ddd_exe = $test->catfile('work', 'subdir', "ddd$_exe");

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Build 'subdir/Conscript';
_EOF_

$test->write(['repository', 'aaa.c'], <<'_EOF_');
main()
{
	printf("repository/aaa.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'bbb.c'], <<'_EOF_');
main()
{
	printf("repository/bbb.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'subdir', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$ccc_exe', 'ccc.c';
Program \$env '$ddd_exe', 'ddd.c';
_EOF_

$test->write(['repository', 'subdir', 'ccc.c'], <<'_EOF_');
main()
{
	printf("repository/subdir/ccc.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'subdir', 'ddd.c'], <<'_EOF_');
main()
{
	printf("repository/subdir/ddd.c\n");
	exit (0);
}
_EOF_


# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->execute(prog => $work_bbb, stdout => <<_EOF_);
repository/bbb.c
_EOF_

$test->execute(prog => $work_subdir_ccc, stdout => <<_EOF_);
repository/subdir/ccc.c
_EOF_

$test->execute(prog => $work_subdir_ddd, stdout => <<_EOF_);
repository/subdir/ddd.c
_EOF_

# Make the repository writable again so we can build in it.
$test->writable('repository', 1);

$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->execute(prog => $repository_bbb, stdout => <<_EOF_);
repository/bbb.c
_EOF_

$test->execute(prog => $repository_subdir_ccc, stdout => <<_EOF_);
repository/subdir/ccc.c
_EOF_

$test->execute(prog => $repository_subdir_ddd, stdout => <<_EOF_);
repository/subdir/ddd.c
_EOF_

# Make the repository non-writable again,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => "$flags -r", targets => "bbb$_o $bbb_exe");
$test->must_not_exist($work_bbb_o);
$test->must_not_exist($work_bbb_exe);

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->execute(prog => $work_subdir_ccc, stdout => <<_EOF_);
repository/subdir/ccc.c
_EOF_

$test->execute(prog => $work_subdir_ddd, stdout => <<_EOF_);
repository/subdir/ddd.c
_EOF_

$test->run('chdir' => 'work', flags => "$flags -r", targets => "subdir");

$test->must_not_exist($work_bbb_o);
$test->must_not_exist($work_bbb_exe);
$test->must_not_exist($work_subdir_ccc_o);
$test->must_not_exist($work_subdir_ccc_exe);
$test->must_not_exist($work_subdir_ddd_o);
$test->must_not_exist($work_subdir_ddd_exe);

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->run('chdir' => 'work', flags => "$flags -r", targets => ".");

$test->must_not_exist($work_aaa_o);
$test->must_not_exist($work_aaa_exe);
$test->must_not_exist($work_bbb_o);
$test->must_not_exist($work_bbb_exe);
$test->must_not_exist($work_subdir_ccc_o);
$test->must_not_exist($work_subdir_ccc_exe);
$test->must_not_exist($work_subdir_ddd_o);
$test->must_not_exist($work_subdir_ddd_exe);

#
$test->pass;
__END__
