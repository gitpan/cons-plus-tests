#! /usr/bin/env perl
#
#	Create two executables from two .c files in the repository.
#	Build in a work subdirectory; everything is up-to-date.
#	Touch one of the executables in the repository, making its
#	time-stamp out-of-sync with the .consign file.  Create a
#	work Construct file that specifies Repository_Sig_Times_OK
#	0; build; everything should still be "up-to-date" despite
#	the mismatched time-stamps.  Create a work Construct file
#	that specifies Repository_Sig_Times_OK 1; build; check that
#	a work copy of the executable was built.
#

# $Id: t0143.t,v 1.5 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Repository_Sig_Times_OK');

$test->subdir('work', 'repository');

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$workpath_repository = $test->workpath('repository');
$repository_aaa = $test->catfile('repository', 'aaa');
$repository_aaa_exe = $test->catfile('repository', $aaa_exe);
$repository_bbb = $test->catfile('repository', 'bbb');
$work_aaa = $test->catfile('work', 'aaa');
$work_aaa_exe = $test->catfile('work', $aaa_exe);
$work_bbb_exe = $test->catfile('work', $bbb_exe);

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
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

$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_

$test->execute(prog => $repository_bbb, stdout => <<_EOF_);
repository/bbb.c
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($work_aaa_exe);
$test->must_not_exist($work_bbb_exe);

$test->writable('repository', 1);

# Theoretically, sleep(1) should be sufficient to ensure a newer time.
# Empirically, that sometimes fails on Windows NT, whereas sleep(2)
# always seems to work as we want.  Don't fight city hall.
$test->sleep(2);	# ENSURE TIME IS NEWER

$test->touch(time, $repository_aaa_exe);

$test->writable('repository', 0);

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Repository_Sig_Times_OK 0;
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($work_aaa_exe);
$test->must_not_exist($work_bbb_exe);

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Repository_Sig_Times_OK 1;
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_aaa, stdout => <<_EOF_);
repository/aaa.c
_EOF_
$test->must_not_exist($work_bbb_exe);

#
$test->pass;
__END__
