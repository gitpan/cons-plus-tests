#! /usr/bin/env perl
#
#	Generate one file in the current directory and one file in a
#	subdirectory, each by copying an input file, specified as a
#	Command source file, and a separate dependency file, specified
#	via Depends.  Both dependency files live in the subdirectory.
#	Build both files; check that they build correctly.  Update both
#	dependency files; check that both targets re-built correctly.
#	Remove the top-level file's dependency file.  Re-build just the
#	subdirectory file; check that it re-built correctly.
#

# $Id: t0027.t,v 1.6 2000/06/26 14:44:14 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Depends');

$test->subdir('subdir');

#
$subdir_foo_dep = $test->catfile('subdir', 'foo.dep');
$subdir_bar_dep = $test->catfile('subdir', 'bar.dep');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Depends \$env 'foo', '$subdir_foo_dep';
Command \$env 'foo', 'foo.in', qq(
	\Q$^X\E -n -e "print" %< $subdir_foo_dep > %>
);
Build 'subdir/Conscript';
_EOF_

$test->write('foo.in', <<'_EOF_');
foo.in
_EOF_

$test->write($subdir_foo_dep, <<'_EOF_');
subdir/foo.dep 1
_EOF_

$test->write(['subdir', 'Conscript'], <<_EOF_);
Import qw( env );
Depends \$env 'bar', 'bar.dep';
Command \$env 'bar', 'bar.in', qq(
	\Q$^X\E -n -e "print" %< $subdir_bar_dep > %>
);
_EOF_

$test->write(['subdir', 'bar.in'], <<'_EOF_');
subdir/bar.in
_EOF_

$test->write($subdir_bar_dep, <<'_EOF_');
subdir/bar.dep 1
_EOF_

#
$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo.in
subdir/foo.dep 1
_EOF_

$test->file_matches(['subdir', 'bar'], <<_EOF_);
subdir/bar.in
subdir/bar.dep 1
_EOF_

#
$test->write($subdir_foo_dep, <<'_EOF_');
subdir/foo.dep 2
_EOF_

$test->write($subdir_bar_dep, <<'_EOF_');
subdir/bar.dep 2
_EOF_

#
$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo.in
subdir/foo.dep 2
_EOF_

$test->file_matches(['subdir', 'bar'], <<_EOF_);
subdir/bar.in
subdir/bar.dep 2
_EOF_

#
$test->unlink($subdir_foo_dep);

$test->write($subdir_bar_dep, <<'_EOF_');
subdir/bar.dep 3
_EOF_

$test->run(targets => "subdir");

$test->file_matches(['subdir', 'bar'], <<_EOF_);
subdir/bar.in
subdir/bar.dep 3
_EOF_

#
$test->pass;
__END__
