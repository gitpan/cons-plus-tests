#! /usr/bin/env perl
#
#	Build a file by copying an input file to output, along with
#	two separate dependency files.	Specify one Depends file using
#	an absolute path name with a lower-case initial letter (drive
#	letter on WIN32 systems).  Specify the other Depends file using an
#	initial upper-case letter.  Build the file.  Update the lower-case
#	Depends file and then try to re-build specifying an absolute path
#	with an initial upper-case letter.  Then update the upper-case
#	Depends file and re-build specifying an initial lower-case letter.
#	Check that the file is (re-)built properly after each run.
#

# $Id: t0074.t,v 1.1 2000/06/26 16:02:43 knight Exp $

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

use Test::Cmd::Cons qw($_is_win32);

$test = Test::Cmd::Cons->new(string => 'case-insensitivity');

# This test doesn't apply to case-sensitive systems, so just pass it.
# XXX The following check would be more general, but the
#     case_tolerant method is a late addition to File::Spec,
#     so not everyone has it.
#$test->pass if ! $test->case_tolerant;
$test->pass if ! $_is_win32;

#
$lc_workpath = lcfirst($test->workpath);
$uc_workpath = ucfirst($test->workpath);

$lc_workpath_foo = $test->catfile($lc_workpath, 'foo');
$uc_workpath_foo = $test->catfile($uc_workpath, 'foo');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Depends \$env '$lc_workpath_foo', 'lc_dep';
Depends \$env '$uc_workpath_foo', 'uc_dep';
Command \$env 'foo', 'foo.in', qq(
	\Q$^X\E -n -e "print" %< lc_dep uc_dep > %>
);
_EOF_

$test->write('foo.in', <<'_EOF_');
foo.in
_EOF_

$test->write('lc_dep', <<'_EOF_');
lc_dep 1
_EOF_

$test->write('uc_dep', <<'_EOF_');
uc_dep 1
_EOF_

#
$test->run(targets => '.');

$test->file_matches('foo', <<_EOF_);
foo.in
lc_dep 1
uc_dep 1
_EOF_

#
$test->write('lc_dep', <<'_EOF_');
lc_dep 2
_EOF_

#
$test->run(targets => $uc_workpath);

$test->file_matches('foo', <<_EOF_);
foo.in
lc_dep 2
uc_dep 1
_EOF_

#
$test->write('uc_dep', <<'_EOF_');
uc_dep 2
_EOF_

#
$test->run(targets => $lc_workpath);

$test->file_matches('foo', <<_EOF_);
foo.in
lc_dep 2
uc_dep 2
_EOF_

#
$test->pass;
__END__
