#! /usr/bin/env perl
#
#	Define three executables to be compiled from separate .c files
#	in the local directory, and three in a subdirectory.  Specify
#	'Default' target of one of the executables in each directory.
#	Invoke cons with no arguments.  Make sure only the default
#	executables get built.  Invoke cons with '.' as argument.
#	Make sure the rest of the executables get built.
#

# $Id: t0021.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Default');

$test->subdir('subdir');

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$eee_exe = "eee$_exe";
$fff_exe = "fff$_exe";
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_ddd = $test->catfile('subdir', 'ddd');
$subdir_ddd_exe = $test->catfile('subdir', $ddd_exe);
$subdir_eee = $test->catfile('subdir', 'eee');
$subdir_eee_exe = $test->catfile('subdir', $eee_exe);
$subdir_fff = $test->catfile('subdir', 'fff');
$subdir_fff_exe = $test->catfile('subdir', $fff_exe);

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Default qw(
	$bbb_exe
);
Build qw(
	$subdir_Conscript
);
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Default qw(
	$eee_exe
);
Program \$env '$ddd_exe', 'ddd.c';
Program \$env '$eee_exe', 'eee.c';
Program \$env '$fff_exe', 'fff.c';
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

$test->write('ccc.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("ccc.c\n");
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

$test->write(['subdir', 'eee.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/eee.c\n");
	exit (0);
}
_EOF_

$test->write(['subdir', 'fff.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/fff.c\n");
	exit (0);
}
_EOF_

#
$test->run(targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($ccc_exe);
$test->must_not_exist($subdir_ddd_exe);
$test->must_not_exist($subdir_fff_exe);

$test->execute(prog => 'bbb', stdout => <<_EOF_);
\Qbbb.c\E
_EOF_

$test->execute(prog => $subdir_eee, stdout => <<_EOF_);
\Qsubdir/eee.c\E
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'aaa', stdout => <<_EOF_);
\Qaaa.c\E
_EOF_

$test->execute(prog => 'ccc', stdout => <<_EOF_);
\Qccc.c\E
_EOF_

$test->execute(prog => $subdir_ddd, stdout => <<_EOF_);
\Qsubdir/ddd.c\E
_EOF_

$test->execute(prog => $subdir_fff, stdout => <<_EOF_);
\Qsubdir/fff.c\E
_EOF_

#
$test->run(flags => "-r", targets => ".");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($ccc_exe);
$test->must_not_exist($subdir_ddd_exe);
$test->must_not_exist($subdir_eee_exe);
$test->must_not_exist($subdir_fff_exe);

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Default qw(
	subdir
);
Build qw(
	$subdir_Conscript
);
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
_EOF_

$test->run(targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($ccc_exe);

$test->execute(prog => $subdir_ddd, stdout => <<_EOF_);
\Qsubdir/ddd.c\E
_EOF_

$test->execute(prog => $subdir_eee, stdout => <<_EOF_);
\Qsubdir/eee.c\E
_EOF_

$test->execute(prog => $subdir_fff, stdout => <<_EOF_);
\Qsubdir/fff.c\E
_EOF_

#
$test->pass;
__END__
