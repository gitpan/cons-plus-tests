#! /usr/bin/env perl
#
#	In the repository subdirectory, create three .c files in
#	the local directory, and two .c files in a subdirectory,
#	with Construct and Conscript files to create separate
#	executables from each.  In the work subdirectory, invoke
#	cons with no arguments and make sure nothing gets built.
#	In the work subdirectory, invoke cons -R with one of the
#	local executables as an argument and make sure only it gets
#	built.  In the work subdirectory, invoke cons -R with one
#	of the local executables and the subdirectory as arguments
#	and make sure only those executables get built.  In the
#	work subdirectory, invoke cons -R with '.' as an argument
#	and make sure the last local executable gets built.
#

# $Id: t0131.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'selective targeting, -R');

$test->subdir('work', 'repository', ['repository', 'src']);

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$xxx_exe = "xxx$_exe";
$yyy_exe = "yyy$_exe";
$workpath_repository = $test->workpath('repository');
$work_aaa = $test->catfile('work', 'aaa');
$work_bbb = $test->catfile('work', 'bbb');
$work_ccc = $test->catfile('work', 'ccc');
$work_src_xxx = $test->catfile('work', 'src', 'xxx');
$work_src_yyy = $test->catfile('work', 'src', 'yyy');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
Build qw (
	src/Conscript
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

$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$xxx_exe', 'xxx.c';
Program \$env '$yyy_exe', 'yyy.c';
_EOF_

$test->write(['repository', 'src', 'xxx.c'], <<'_EOF_');
main()
{
	printf("repository/src/xxx.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'src', 'yyy.c'], <<'_EOF_');
main()
{
	printf("repository/src/yyy.c\n");
	exit (0);
}
_EOF_


#
# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => "");
$test->must_not_exist(['work', $aaa_exe]);
$test->must_not_exist(['work', $bbb_exe]);
$test->must_not_exist(['work', $ccc_exe]);
$test->must_not_exist(['work', 'src', $xxx_exe]);
$test->must_not_exist(['work', 'src', $yyy_exe]);

$test->run('chdir' => 'work', flags => $flags, targets => "$aaa_exe");
$test->must_not_exist(['work', $bbb_exe]);
$test->must_not_exist(['work', $ccc_exe]);
$test->must_not_exist(['work', 'src', $xxx_exe]);
$test->must_not_exist(['work', 'src', $yyy_exe]);

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => "$bbb_exe src");
$test->must_not_exist(['work', $ccc_exe]);

$test->execute(prog => $work_bbb, stdout => <<_EOF_);
repository/bbb.c
_EOF_

$test->execute(prog => $work_src_xxx, stdout => <<_EOF_);
repository/src/xxx.c
_EOF_

$test->execute(prog => $work_src_yyy, stdout => <<_EOF_);
repository/src/yyy.c
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");
$test->execute(prog => $work_ccc, stdout => <<_EOF_);
repository/ccc.c
_EOF_

#
$test->pass;
__END__
