#! /usr/bin/env perl
#
#	Create Construct and two Conscript files for creating four
#	executables, two from .c files in the local directory and
#	two from .c files in a subdirectory.  Invoke cons -pw,
#	compare the output against expected results.
#

# $Id: t0033.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-pw');

$test->subdir('subdir');

#
$aaa_o = "aaa$_o";
$aaa_exe = "aaa$_exe";
$bbb_o = "bbb$_o";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc_exe = $test->catfile('subdir', "ccc$_exe");
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd_exe = $test->catfile('subdir', "ddd$_exe");

#
# The -pw output contains line numbers in the Construct/Conscript file.
# Since $test->cons_env can be set externally (via the CONSENV environment
# variable) and would have a varied number of lines, this would throw
# off our line counts.  Sidestep this by creating the Cons environment
# in the Construct file and exporting it to a Conscript file (in the
# same directory).  This way, the line numbers in the Conscript file
# stay constant regardless of how many entries CONSENV has.
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Build 'Conscript';
_EOF_

$test->write('Conscript', <<_EOF_);
Import qw( env );
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
Import qw( env );
Program \$env '$ccc_exe', 'ccc.c';
Program \$env '$ddd_exe', 'ddd.c';
_EOF_

$test->write(['subdir', 'ddd.c'], <<_EOF_);
int
main(int argc, char *argv[])
{
	printf("subdir/ccc.c\n");
	exit (0);
}
_EOF_

$test->write(['subdir', 'ddd.c'], <<_EOF_);
int
main(int argc, char *argv[])
{
	printf("subdir/ddd.c\n");
	exit (0);
}
_EOF_

$test->run(flags => "-pw", targets => ".", stdout => <<_EOF_, stderr => '');
\Q$aaa_exe\E: cons::Program in "Conscript", line 2
\Q$aaa_o\E: cons::Program in "Conscript", line 2
\Q$bbb_exe\E: cons::Program in "Conscript", line 3
\Q$bbb_o\E: cons::Program in "Conscript", line 3
\Q$subdir_ccc_exe\E: cons::Program in "\Q$subdir_Conscript\E", line 2
\Q$subdir_ccc_o\E: cons::Program in "\Q$subdir_Conscript\E", line 2
\Q$subdir_ddd_exe\E: cons::Program in "\Q$subdir_Conscript\E", line 3
\Q$subdir_ddd_o\E: cons::Program in "\Q$subdir_Conscript\E", line 3
_EOF_

$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($subdir_ccc_exe);
$test->must_not_exist($subdir_ddd_exe);

#
$test->pass;
__END__
