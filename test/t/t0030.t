#! /usr/bin/env perl
#
#	Create two executables from .c files in the local directory,
#	and two in a subdirectory.  Remove all derived files (-r).
#	Remove the first subdirectory .c file.  Build the subdirectory;
#	see it fail; make sure neither .o or executable was built.
#	Remove the first local directory .c file.  Build the world.
#	Make sure no .o files nor executables were built.  Build
#	-k the subdirectory.  Make sure the second "masked"
#	subdirectory executable was built.    Build -k the world.
#	Make sure the second "masked" local directory executable
#	was built.
#

# $Id: t0030.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-k');

$test->subdir('subdir');

#
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$aaa_o = "aaa$_o";
$bbb_o = "bbb$_o";
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc = $test->catfile('subdir', 'ccc');
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd = $test->catfile('subdir', 'ddd');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Build '$subdir_Conscript';
_EOF_

$test->write('aaa.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("aaa.c\n");
	exit (0);
}
_EOF_

$test->write('bbb.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("bbb.c\n");
	exit (0);
}
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$ccc_exe', 'ccc.c';
Program \$env '$ddd_exe', 'ddd.c';
_EOF_

$test->write(['subdir', 'ccc.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/ccc.c\n");
	exit (0);
}
_EOF_

$test->write(['subdir', 'ddd.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/ddd.c\n");
	exit (0);
}
_EOF_

#
$expect_aaa = <<'_EOF_';
aaa.c
_EOF_

$expect_bbb = <<'_EOF_';
bbb.c
_EOF_

$expect_ccc = <<'_EOF_';
subdir/ccc.c
_EOF_

$expect_ddd = <<'_EOF_';
subdir/ddd.c
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'aaa', stdout => $expect_aaa);
$test->execute(prog => 'bbb', stdout => $expect_bbb);
$test->execute(prog => $subdir_ccc, stdout => $expect_ccc);
$test->execute(prog => $subdir_ddd, expeddd=> $expect_ddd);

#
$test->up_to_date(targets => ".");

#
$test->run(flags => "-r", targets => ".");

$test->unlink($test->catfile('subdir', 'ccc.c'));

#
$test->run(targets => "subdir", fail => '$? == 0'); # expect failure

$test->must_not_exist($subdir_ccc_o);
$test->must_not_exist(['subdir', $ccc_exe]);
$test->must_not_exist($subdir_ddd_o);
$test->must_not_exist(['subdir', $ddd_exe]);

$test->unlink('aaa.c');

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure

$test->must_not_exist($aaa_o);
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_o);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($subdir_ccc_o);
$test->must_not_exist(['subdir', $ccc_exe]);
$test->must_not_exist($subdir_ddd_o);
$test->must_not_exist(['subdir', $ddd_exe]);

#
$test->run(flags => "-k", targets => "subdir", fail => '$? == 0'); # expect failure

$test->must_not_exist($subdir_ccc_o);
$test->must_not_exist($subdir_ccc);
$test->execute(prog => $subdir_ddd, expeddd=> $expect_ddd);

#
$test->run(flags => "-k", targets => ".", fail => '$? == 0'); # expect failure

$test->must_not_exist($aaa_o);
$test->must_not_exist($aaa_exe);
$test->execute(prog => 'bbb', stdout => $expect_bbb);

#
$test->pass;
__END__