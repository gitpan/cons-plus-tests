#! /usr/bin/env perl
#
#	Compile three separate executables from separate .c files
#	in the local directory, and two separate executables from
#	separate .c files in a subdirectory.  Invoke cons with no
#	arguments and make sure nothing gets built.  Supply one of
#	the local executables as an argument and make sure only it
#	gets built.  Supply one of the local executables and the
#	subdirectory as arguments and make sure only those executables
#	get built.  Supply '.' as an argument and make sure the
#	last local executable gets built.
#

# $Id: t0020.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'selective targeting');

$test->subdir('src');

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$xxx_exe = "xxx$_exe";
$yyy_exe = "yyy$_exe";
$src_Conscript = $test->catfile('src', 'Conscript');
$src_xxx = $test->catfile('src', 'xxx');
$src_yyy = $test->catfile('src', 'yyy');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Program \$env '$ccc_exe', 'ccc.c';
Build qw (
	$src_Conscript
);
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

$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$xxx_exe', 'xxx.c';
Program \$env '$yyy_exe', 'yyy.c';
_EOF_

$test->write(['src', 'xxx.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("src/xxx.c\n");
	exit (0);
}
_EOF_

$test->write(['src', 'yyy.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("src/yyy.c\n");
	exit (0);
}
_EOF_

#
$test->run(targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($ccc_exe);
$test->must_not_exist(['src', $xxx_exe]);
$test->must_not_exist(['src', $yyy_exe]);

#
$test->run(targets => $aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($ccc_exe);
$test->must_not_exist(['src', $xxx_exe]);
$test->must_not_exist(['src', $yyy_exe]);

$test->execute(prog => 'aaa', stdout => <<'_EOF_');
aaa.c
_EOF_

#
$test->run(targets => "$bbb_exe src");
$test->must_not_exist($ccc_exe);

$test->execute(prog => 'bbb', stdout => <<'_EOF_');
bbb.c
_EOF_

$test->execute(prog => $src_xxx, stdout => <<'_EOF_');
src/xxx.c
_EOF_

$test->execute(prog => $src_yyy, stdout => <<'_EOF_');
src/yyy.c
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'ccc', stdout => <<'_EOF_');
ccc.c
_EOF_

#
$test->pass;
__END__
