#! /usr/bin/env perl
#
#	Create Construct and Conscript files for creating four
#	executables, two from .c files in the local directory and
#	two from .c files in a subdirectory.  Invoke cons -pa,
#	compare the output against expected results.
#
#	NOTE:  THIS TEST EXAMINES THE ACTIONS USED TO BUILD FILES.
#

# $Id: t0032.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-pa');

$test->subdir('subdir');

$CC = $test->cons_env_val('CC') || 'cc';
$LINK = $test->cons_env_val('LINK') || $CC;

#
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$aaa_o = "aaa$_o";
$aaa_exe = "aaa$_exe";
$bbb_o = "bbb$_o";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$subdir_ccc_c = $test->catfile('subdir', 'ccc.c');
$subdir_ccc_o = $test->catfile('subdir', "ccc$_o");
$subdir_ccc_exe = $test->catfile('subdir', $ccc_exe);
$subdir_ddd_c = $test->catfile('subdir', 'ddd.c');
$subdir_ddd_o = $test->catfile('subdir', "ddd$_o");
$subdir_ddd_exe = $test->catfile('subdir', $ddd_exe);

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
# Examining Cons build output:
#
# It would be ideal to do an exact match against expected output,
# but that gets into having to second-guess the build commands:
# the exact flags, order of arguments, etc.
#
# Instead, we settle for the following lowest-common-denominator
# requirements:
#
#   --	the $LINK or $CC command is the first thing on the line;
#   --	the $LINK or $CC command is followed by a space;
#   --	the $LINK command is followed by the target executable
#	file and then the object file(s) somewhere on the line
#   --	the $CC command is followed by the source file and
#	then the target object file somewhere on the line.
#
# Since our expectation is that the command lines explicitly list
# their target and input files, our %CCCOM command can't use the MSVC
# shortcut of -Fo (and no object name) to build foo.obj automatically
# from foo.c; building with MSVC requires explicit use of -Fo%>.  Ditto
# for the MSVC linker's -out:%> option on the %LINKCOM command.
#
# This also means that we can't look for output file name matches with
# an initial \b (word boundary), because MSVC won't let us put a space
# between them, and the '-Fo' concatenated with our object name means
# it's not a word boundary.
#
$test->run(flags => "-pa", targets => ".", stdout => <<_EOF_, stderr => '');
\Q$aaa_exe\E:
\Q...\E $LINK .*aaa\\b.*\\b\Q$aaa_o\E.*
\Q$aaa_o\E:
\Q...\E $CC .*\\b\Qaaa.c\E\\b.*\Q$aaa_o\E\\b.*
\Q$bbb_exe\E:
\Q...\E $LINK .*bbb\\b.*\\b\Q$bbb_o\E.*
\Q$bbb_o\E:
\Q...\E $CC .*\\b\Qbbb.c\E\\b.*\Q$bbb_o\E\\b.*
\Q$subdir_ccc_exe\E:
\Q...\E $LINK .*\Q$subdir_ccc_exe\E\\b.*\\b\Q$subdir_ccc_o\E.*
\Q$subdir_ccc_o\E:
\Q...\E $CC .*\\b\Q$subdir_ccc_c\E\\b.*\Q$subdir_ccc_o\E\\b.*
\Q$subdir_ddd_exe\E:
\Q...\E $LINK .*\Q$subdir_ddd_exe\E\\b.*\\b\Q$subdir_ddd_o\E.*
\Q$subdir_ddd_o\E:
\Q...\E $CC .*\\b\Q$subdir_ddd_c\E\\b.*\Q$subdir_ddd_o\E\\b.*
_EOF_

$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($subdir_ccc_exe);
$test->must_not_exist($subdir_ddd_exe);

#
$test->pass;
__END__
