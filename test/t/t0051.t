#! /usr/bin/env perl
#
#	Create a Construct file and a Conscript file in a subdirectory.
#	The Construct file prints to an output file the result of three
#	DirPath calls, one each to the current directory, a non-existent
#	subdirectory, and a subdirectory.  The Conscript prints to
#	an output file the result of a single DirPath call with three
#	arguments, one each to the current directory, a non-existent
#	subdirectory, and a subdirectory, but returned to an array.
#	Check the output files.
#

# $Id: t0051.t,v 1.2 2000/06/01 22:00:45 knight Exp $

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
use Config;

$test = Test::Cmd::Cons->new(string => 'DirPath');

$test->subdir('subdir', ['subdir', 'below']);

#
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_bbb_out = $test->catfile('subdir', 'bbb.out');
$subdir_yyy = $test->catfile('subdir', 'yyy');
$subdir_below = $test->catfile('subdir', 'below');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Build '$subdir_Conscript';
\$dp_dot = DirPath '.';
\$dp_xxx = DirPath 'xxx';
\$dp_subdir = DirPath 'subdir';
Command \$env 'aaa.out', 'aaa.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'dp_dot = \$dp_dot', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'dp_xxx = \$dp_xxx', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'dp_subdir = \$dp_subdir', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
Import qw( env );
\@dp_arr = DirPath '.', 'yyy', 'below';
Command \$env 'bbb.out', 'bbb.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'dp_arr = \@dp_arr', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

$test->write('aaa.pl', <<_EOF_);
$Config{startperl}
print "aaa.pl\\n";
exit(0);
_EOF_

$test->write(['subdir', 'bbb.pl'], <<_EOF_);
$Config{startperl}
print "subdir/bbb.pl\\n";
exit(0);
_EOF_

$test->run(targets => "."); # expect failure

$test->file_matches('aaa.out', <<_EOF_);
\Qaaa.pl\E
\Qdp_dot = .\E
\Qdp_xxx = xxx\E
\Qdp_subdir = subdir\E
_EOF_

$test->file_matches($subdir_bbb_out, <<_EOF_);
\Qsubdir/bbb.pl\E
\Qdp_arr = subdir $subdir_yyy $subdir_below\E
_EOF_

#
$test->pass;
__END__
