#! /usr/bin/env perl
#
#	Make three sub-subdirectories, each of which builds two Programs.
#	The intermediate subdirectory Conscript file specifies two of
#	these directories as Default.  Invoke Cons from one of the default
#	sub-subdirectories; check that nothing was built.  Invoke Cons -t
#	from that sub-subdirectory; check that its Programs were built as
#	default.  Invoke Cons; check that the other Default Programs were
#	built.	Invoke Cons .; check that the last Programs were built.
#	Invoke Cons -t -r from the other Default sub-subdirectory; check
#	that only its Programs were removed.  Invoke Cons -r; check that
#	the original Default sub-subdirectory's Programs were removed.
#

# $Id: t0060.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-t, Default');

$test->subdir('sub', ['sub', 'dir1'], ['sub', 'dir2'], ['sub', 'dir3']);

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$eee_exe = "eee$_exe";
$fff_exe = "fff$_exe";
$sub_Conscript = $test->catfile('sub', 'Conscript');
$sub_dir1_aaa = $test->catfile('sub', 'dir1', 'aaa');
$sub_dir1_aaa_exe = $test->catfile('sub', 'dir1', $aaa_exe);
$sub_dir1_bbb = $test->catfile('sub', 'dir1', 'bbb');
$sub_dir1_bbb_exe = $test->catfile('sub', 'dir1', $bbb_exe);
$sub_dir2 = $test->catfile('sub', 'dir2');
$sub_dir2_ccc = $test->catfile('sub', 'dir2', 'ccc');
$sub_dir2_ccc_exe = $test->catfile('sub', 'dir2', $ccc_exe);
$sub_dir2_ddd = $test->catfile('sub', 'dir2', 'ddd');
$sub_dir2_ddd_exe = $test->catfile('sub', 'dir2', $ddd_exe);
$sub_dir3 = $test->catfile('sub', 'dir3');
$sub_dir3_eee = $test->catfile('sub', 'dir3', 'eee');
$sub_dir3_eee_exe = $test->catfile('sub', 'dir3', $eee_exe);
$sub_dir3_fff = $test->catfile('sub', 'dir3', 'fff');
$sub_dir3_fff_exe = $test->catfile('sub', 'dir3', $fff_exe);
$dir1_Conscript = $test->catfile('dir1', 'Conscript');
$dir2_Conscript = $test->catfile('dir2', 'Conscript');
$dir3_Conscript = $test->catfile('dir3', 'Conscript');

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export 'env';
Build '$sub_Conscript';
_EOF_

$test->write($sub_Conscript, <<_EOF_);
Import 'env';
Build qw(
	$dir1_Conscript
	$dir2_Conscript
	$dir3_Conscript
);
Default qw(
	dir2
	dir3
);
_EOF_

$test->write(['sub', 'dir1', 'Conscript'], <<_EOF_);
Import 'env';
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
_EOF_

$test->write(['sub', 'dir2', 'Conscript'], <<_EOF_);
Import 'env';
Program \$env '$ccc_exe', 'ccc.c';
Program \$env '$ddd_exe', 'ddd.c';
_EOF_

$test->write(['sub', 'dir3', 'Conscript'], <<_EOF_);
Import 'env';
Program \$env '$eee_exe', 'eee.c';
Program \$env '$fff_exe', 'fff.c';
_EOF_

$test->write(['sub', 'dir1', 'aaa.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir1/aaa.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'dir1', 'bbb.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir1/bbb.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'dir2', 'ccc.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir2/ccc.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'dir2', 'ddd.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir2/ddd.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'dir3', 'eee.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir3/eee.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'dir3', 'fff.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("sub/dir3/fff.c\n");
	exit (0);
}
_EOF_

#
$test->run('chdir' => $sub_dir2, targets => "");
$test->must_not_exist($sub_dir1_aaa_exe);
$test->must_not_exist($sub_dir1_bbb_exe);
$test->must_not_exist($sub_dir2_ccc_exe);
$test->must_not_exist($sub_dir2_ddd_exe);
$test->must_not_exist($sub_dir3_eee_exe);
$test->must_not_exist($sub_dir3_fff_exe);

$test->run('chdir' => $sub_dir2, flags => '-t', targets => "");
$test->must_not_exist($sub_dir1_aaa_exe);
$test->must_not_exist($sub_dir1_bbb_exe);
$test->must_not_exist($sub_dir3_eee_exe);
$test->must_not_exist($sub_dir3_fff_exe);

$test->execute(prog => $sub_dir2_ccc, stdout => <<_EOF_);
sub/dir2/ccc.c
_EOF_

$test->execute(prog => $sub_dir2_ddd, stdout => <<_EOF_);
sub/dir2/ddd.c
_EOF_

$test->run(targets => "");
$test->must_not_exist($sub_dir1_aaa_exe);
$test->must_not_exist($sub_dir1_bbb_exe);

$test->execute(prog => $sub_dir3_eee, stdout => <<_EOF_);
sub/dir3/eee.c
_EOF_

$test->execute(prog => $sub_dir3_fff, stdout => <<_EOF_);
sub/dir3/fff.c
_EOF_

$test->run(targets => ".");

$test->execute(prog => $sub_dir1_aaa, stdout => <<_EOF_);
sub/dir1/aaa.c
_EOF_

$test->execute(prog => $sub_dir1_bbb, stdout => <<_EOF_);
sub/dir1/bbb.c
_EOF_

$test->run('chdir' => $sub_dir3, flags => '-t -r', targets => "");
$test->must_exist($sub_dir1_aaa_exe);
$test->must_exist($sub_dir1_bbb_exe);
$test->must_exist($sub_dir2_ccc_exe);
$test->must_exist($sub_dir2_ddd_exe);
$test->must_not_exist($sub_dir3_eee_exe);
$test->must_not_exist($sub_dir3_fff_exe);

$test->run(flags => '-r', targets => "");
$test->must_exist($sub_dir1_aaa_exe);
$test->must_exist($sub_dir1_bbb_exe);
$test->must_not_exist($sub_dir2_ccc_exe);
$test->must_not_exist($sub_dir2_ddd_exe);
$test->must_not_exist($sub_dir3_eee_exe);
$test->must_not_exist($sub_dir3_fff_exe);

$test->pass;
__END__
