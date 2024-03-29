#! /usr/bin/env perl
#
#	Create Construct and Conscript files for creating four
#	executables, two from .c files in the local directory and
#	two from .c files in a subdirectory.  Invoke cons -wf file.
#	Compare the -wf output against expected results.  Make sure
#	the executables were generated correctly.
#

# $Id: t0035.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-wf file');

$test->subdir('subdir');

#
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$aaa_o = "aaa$_o";
$bbb_o = "bbb$_o";
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$subdir_ccc = $test->catfile('subdir', 'ccc');
$subdir_ccc_c = $test->catfile('subdir', 'ccc.c');
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc_exe = $test->catfile('subdir', "ccc$_exe");
$subdir_ddd = $test->catfile('subdir', 'ddd');
$subdir_ddd_c = $test->catfile('subdir', 'ddd.c');
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd_exe = $test->catfile('subdir', "ddd$_exe");

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

$test->write($subdir_ccc_c, <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/ccc.c\n");
	exit (0);
}
_EOF_

$test->write($subdir_ddd_c, <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/ddd.c\n");
	exit (0);
}
_EOF_

#
$test->run(flags => "-wf wf.out", targets => ".");

$test->file_matches("wf.out", <<_EOF_);
\Q$aaa_exe\E
\Q$aaa_o\E
\Qaaa.c\E
\Q$bbb_exe\E
\Q$bbb_o\E
\Qbbb.c\E
\Q$subdir_ccc_exe\E
\Q$subdir_ccc_o\E
\Q$subdir_ccc_c\E
\Q$subdir_ddd_exe\E
\Q$subdir_ddd_o\E
\Q$subdir_ddd_c\E
_EOF_

$test->execute(prog => 'aaa', stdout => <<_EOF_);
aaa.c
_EOF_
$test->execute(prog => 'bbb', stdout => <<_EOF_);
bbb.c
_EOF_
$test->execute(prog => $subdir_ccc, stdout => <<_EOF_);
subdir/ccc.c
_EOF_
$test->execute(prog => $subdir_ddd, stdout => <<_EOF_);
subdir/ddd.c
_EOF_

#
$test->pass;
__END__
