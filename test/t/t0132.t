#! /usr/bin/env perl
#
#	Define three executables to be compiled from separate .c files
#	in the repository subdirectory, and three more in a subdirectory
#	of the repository.  Specify a 'Default' target of one of the
#	executables in each subdirectory.  Invoke cons in the work
#	subdirectory with no arguments.  Make sure only the default
#	executables get built.  Invoke cons in the work subdirectory
#	with '.' as argument.  Make sure the rest of the executables
#	get built.
#

# $Id: t0132.t,v 1.6 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Default, -R');

$test->subdir('work', 'repository', ['repository', 'subdir']);

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$eee_exe = "eee$_exe";
$fff_exe = "fff$_exe";
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$workpath_repository = $test->workpath('repository');
$work_aaa = $test->catfile('work', 'aaa');
$work_bbb = $test->catfile('work', 'bbb');
$work_ccc = $test->catfile('work', 'ccc');
$work_subdir_ddd = $test->catfile('work', 'subdir', 'ddd');
$work_subdir_eee = $test->catfile('work', 'subdir', 'eee');
$work_subdir_fff = $test->catfile('work', 'subdir', 'fff');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Build qw(
	$subdir_Conscript
);
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
Default qw(
	$bbb_exe
);
_EOF_

$test->write(['repository', 'subdir', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$ddd_exe', 'ddd.c';
Program \$env '$eee_exe', 'eee.c';
Program \$env '$fff_exe', 'fff.c';
Default qw(
	$eee_exe
);
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

$test->write(['repository', 'ccc.c'], <<'_EOF_');
main()
{
	printf("repository/ccc.c\n");
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

$test->write(['repository', 'subdir', 'eee.c'], <<'_EOF_');
main()
{
	printf("repository/subdir/eee.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'subdir', 'fff.c'], <<'_EOF_');
main()
{
	printf("repository/subdir/fff.c\n");
	exit (0);
}
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => "");
$test->must_not_exist(['work', $aaa_exe]);
$test->must_not_exist(['work', $ccc_exe]);
$test->must_not_exist(['work', 'subdir', $ddd_exe]);
$test->must_not_exist(['work', 'subdir', $fff_exe]);

$test->execute(prog => $work_bbb, stdout => <<_EOF_);
\Qrepository/bbb.c\E
_EOF_

$test->execute(prog => $work_subdir_eee, stdout => <<_EOF_);
\Qrepository/subdir/eee.c\E
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
\Qrepository/aaa.c\E
_EOF_

$test->execute(prog => $work_ccc, stdout => <<_EOF_);
\Qrepository/ccc.c\E
_EOF_

$test->execute(prog => $work_subdir_ddd, stdout => <<_EOF_);
\Qrepository/subdir/ddd.c\E
_EOF_

$test->execute(prog => $work_subdir_fff, stdout => <<_EOF_);
\Qrepository/subdir/fff.c\E
_EOF_

#
$test->pass;
__END__
