#! /usr/bin/env perl
#
#	Define a Construct file that (using Program) creates three
#	derived programs from C source.  The second C source contains
#	a syntax error.  Execute Cons; check that the Cons exit code
#	indicates an error, and that neither the second nor third
#	derived programs were created (i.e., Cons stopped at the error
#	compiling the second program).  Replace the second source file
#	with one that works.  Execute Cons again.  Check that only the
#	second and third files were built.
#
#	NOTE:  THIS TEST EXAMINES THE ACTIONS USED TO BUILD FILES.
#

# $Id: t0046.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'rebuild after Program error');

$CC = $test->cons_env_val('CC') || 'cc';
$LINK = $test->cons_env_val('LINK') || $CC;

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$bbb_o = "bbb$_o";
$ccc_o = "ccc$_o";

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
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
	THIS LINE GENERATES A SYNTAX ERROR
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

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist($bbb_exe);
$test->must_not_exist($ccc_exe);

$test->execute(prog => 'aaa', stdout => <<_EOF_);
aaa.c
_EOF_

$test->write('bbb.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("bbb.c\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".", stdout => <<_EOF_, stderr => '');
$CC .*\\b\Qbbb.c\E\\b.*\Q$bbb_o\E\\b.*
$LINK .*bbb\\b.*\\b\Q$bbb_o\E\\b.*
$CC .*\\b\Qccc.c\E\\b.*\Q$ccc_o\E\\b.*
$LINK .*ccc\\b.*\\b\Q$ccc_o\E\\b.*
_EOF_

#
$test->pass;
__END__
