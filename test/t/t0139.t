#! /usr/bin/env perl
#
#	In a repository subdirectory, create Construct and Conscript
#	files for creating four executables, two from .c files in
#	the local directory and two from .c files in a subdirectory.
#	Invoke cons -d -R in the work subdirectory.  Compare the
#	output against expected results.
#
#	NOTE:  THIS TEST EXAMINES THE ACTIONS USED TO BUILD FILES.
#

# $Id: t0139.t,v 1.5 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => '-d, -R');

$test->subdir('work', 'repository', ['repository', 'subdir']);

$CC = $test->cons_env_val('CC') || 'cc';
$LINK = $test->cons_env_val('LINK') || $CC;

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$workpath_repository = $test->workpath('repository');
$aaa_o = "aaa$_o";
$bbb_o = "bbb$_o";
$subdir_ccc = $test->catfile('subdir', 'ccc');
$subdir_ccc_c = $test->catfile('subdir', 'ccc.c');
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc_exe = $test->catfile('subdir', "ccc$_exe");
$subdir_ddd = $test->catfile('subdir', 'ddd');
$subdir_ddd_c = $test->catfile('subdir', 'ddd.c');
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd_exe = $test->catfile('subdir', "ddd$_exe");
$work_aaa = $test->catfile('work', 'aaa');
$work_bbb = $test->catfile('work', 'bbb');
$work_subdir_ccc = $test->catfile('work', 'subdir', 'ccc');
$work_subdir_ddd = $test->catfile('work', 'subdir', 'ddd');

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

$test->run('chdir' => 'work', flags => "$flags -d", targets => ".", stdout => <<_EOF_);
Target \Q$aaa_exe\E: \Q$aaa_o\E
Checking \Q$aaa_exe\E
  Checking \Q$aaa_o\E
    Checking \Qaaa.c\E
$CC .* \Q$aaa_o\E\\b.*
$LINK .*aaa\\b.*
Target \Q$aaa_o\E: \Qaaa.c\E
Target \Q$bbb_exe\E: \Q$bbb_o\E
Checking \Q$bbb_exe\E
  Checking \Q$bbb_o\E
    Checking \Qbbb.c\E
$CC .* \Q$bbb_o\E\\b.*
$LINK .*bbb\\b.*
Target \Q$bbb_o\E: \Qbbb.c\E
Target \Q$subdir_ccc_exe\E: \Q$subdir_ccc_o\E
Checking \Q$subdir_ccc_exe\E
  Checking \Q$subdir_ccc_o\E
    Checking \Q$subdir_ccc_c\E
$CC .* \Q$subdir_ccc_o\E\\b.*
$LINK .* \Q$subdir_ccc\E\\b.*
Target \Q$subdir_ccc_o\E: \Q$subdir_ccc_c\E
Target \Q$subdir_ddd_exe\E: \Q$subdir_ddd_o\E
Checking \Q$subdir_ddd_exe\E
  Checking \Q$subdir_ddd_o\E
    Checking \Q$subdir_ddd_c\E
$CC .*\Q$subdir_ddd_o\E\\b.*
$LINK .*\Q$subdir_ddd\E\\b.*
Target \Q$subdir_ddd_o\E: \Q$subdir_ddd_c\E
_EOF_

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

#
$test->pass;
__END__
