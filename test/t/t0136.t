#! /usr/bin/env perl
#
#	In a repository subdirectory, create Construct and Conscript
#	files for creating four executables, two from .c files in
#	the local directory and two from .c files in a subdirectory.
#	Invoke cons -p -R in the work subdirectory.  Compare the
#	output against expected results.
#

# $Id: t0136.t,v 1.4 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => '-p, -R');

$test->subdir('work', 'repository', ['repository', 'subdir']);

#
$workpath_repository = $test->workpath('repository');
$aaa_o = "aaa$_o";
$aaa_exe = "aaa$_exe";
$bbb_o = "bbb$_o";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$repository_aaa_exe = $test->catfile('repository', $aaa_exe);
$repository_bbb_exe = $test->catfile('repository', $bbb_exe);
$repository_subdir_ccc_exe = $test->catfile('repository', 'subdir', "ccc$_exe");
$repository_subdir_ddd_exe = $test->catfile('repository', 'subdir', "ddd$_exe");
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc_exe = $test->catfile('subdir', $ccc_exe);
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd_exe = $test->catfile('subdir', $ddd_exe);

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

$test->run('chdir' => 'work', flags => "$flags -p", targets => ".", stdout => <<_EOF_);
\Q$aaa_exe\E
\Q$aaa_o\E
\Q$bbb_exe\E
\Q$bbb_o\E
\Q$subdir_ccc_exe\E
\Q$subdir_ccc_o\E
\Q$subdir_ddd_exe\E
\Q$subdir_ddd_o\E
_EOF_
$test->must_not_exist($repository_aaa_exe);
$test->must_not_exist($repository_bbb_exe);
$test->must_not_exist($repository_subdir_ccc_exe);
$test->must_not_exist($repository_subdir_ddd_exe);

#
$test->pass;
__END__
