#! /usr/bin/env perl
#
#	Create Construct and subdirectory Conscript files, each of
#	which builds two Programs and defines one of them as the
#	Default.  Execute "cons" in the subdirectory; make sure nothing
#	built.  Execute "cons -t" in the subdirectory; make sure
#	that only the subdirectory default was built.  Execute "cons"
#	in the main directory; make sure only the default was built.
#	Execute "cons ." in the main directory; make sure the non-
#	default programs were built.  Execute "cons -t -r" in the
#	subdirectory; make sure only the subdirectory default was
#	removed.  Execute "cons -r" in the main directory; make sure
#	its default was removed.
#

# $Id: t0059.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-t, Default sub-target');

$test->subdir('subdir');

#
$aaa_exe = "aaa$_exe";
$bbb_exe = "bbb$_exe";
$ccc_exe = "ccc$_exe";
$ddd_exe = "ddd$_exe";
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_ccc = $test->catfile('subdir', 'ccc');
$subdir_ccc_exe = $test->catfile('subdir', $ccc_exe);
$subdir_ddd = $test->catfile('subdir', 'ddd');
$subdir_ddd_exe = $test->catfile('subdir', $ddd_exe);

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Program \$env '$bbb_exe', 'bbb.c';
Default '$bbb_exe';
Build qw(
	$subdir_Conscript
);
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$ccc_exe', 'ccc.c';
Program \$env '$ddd_exe', 'ddd.c';
Default '$ddd_exe';
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
$test->run('chdir' => 'subdir', targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($subdir_ccc_exe);
$test->must_not_exist($subdir_ddd_exe);

$test->run('chdir' => 'subdir', flags => '-t', targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_not_exist($subdir_ccc_exe);

$test->execute(prog => $subdir_ddd, stdout => <<_EOF_);
subdir/ddd.c
_EOF_

$test->run(targets => "");
$test->must_not_exist($aaa_exe);
$test->must_not_exist($subdir_ccc_exe);

$test->execute(prog => 'bbb', stdout => <<_EOF_);
bbb.c
_EOF_

$test->run(targets => ".");

$test->execute(prog => 'aaa', stdout => <<_EOF_);
aaa.c
_EOF_

$test->execute(prog => $subdir_ccc, stdout => <<_EOF_);
subdir/ccc.c
_EOF_

$test->run('chdir' => 'subdir', flags => '-t -r', targets => "");
$test->must_exist($aaa_exe);
$test->must_exist($bbb_exe);
$test->must_exist($subdir_ccc_exe);
$test->must_not_exist($subdir_ddd_exe);

$test->run(flags => '-r', targets => "");
$test->must_exist($aaa_exe);
$test->must_not_exist($bbb_exe);
$test->must_exist($subdir_ccc_exe);
$test->must_not_exist($subdir_ddd_exe);

$test->pass;
__END__
