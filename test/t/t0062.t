#! /usr/bin/env perl
#
#	Create two output files by appending the contents of separate
#	input files.  Make one of output files Precious.  Create the files
#	with initial contents; make sure everything built correctly.
#	Update the input file contents.  Build again, making sure that
#	the Precious file has both input versions and the non-Precious
#	file has only the first.
#

# $Id: t0062.t,v 1.4 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons;

$test = Test::Cmd::Cons->new(string => 'Precious');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'aaa.out', 'aaa.in', qq(
	\Q$^X\E -e "while (<>) { print }" %< >> %>
);
Precious 'bbb.out';
Command \$env 'bbb.out', 'bbb.in', qq(
	\Q$^X\E -e "while (<>) { print }" %< >> %>
);
_EOF_

$test->write('aaa.in', <<_EOF_);
aaa.in #1
_EOF_

$test->write('bbb.in', <<_EOF_);
bbb.in #1
_EOF_

$test->run(targets => ".");

$test->file_matches('aaa.out', <<_EOF_);
aaa.in #1
_EOF_

$test->file_matches('bbb.out', <<_EOF_);
bbb.in #1
_EOF_

$test->write('aaa.in', <<_EOF_);
aaa.in #2
_EOF_

$test->write('bbb.in', <<_EOF_);
bbb.in #2
_EOF_

$test->run(targets => ".");

$test->file_matches('aaa.out', <<_EOF_);
aaa.in #2
_EOF_

$test->file_matches('bbb.out', <<_EOF_);
bbb.in #1
bbb.in #2
_EOF_

$test->run(flags => "-r", targets => ".");
$test->must_not_exist('aaa.out');
$test->must_not_exist('bbb.out');

#
$test->pass;
__END__
