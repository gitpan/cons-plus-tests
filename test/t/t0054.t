#! /usr/bin/env perl
#
#	Create a Construct file in a subdirectory.  The Construct file
#	prints to an output file the result of several SplitPath calls,
#	covering the current directory, a subdirectory, an absolute
#	path to a directory outside the current tree, and an absolute
#	path to a subdirectory within the tree.  Check the output file.
#

# $Id: t0054.t,v 1.5 2000/06/19 22:02:00 knight Exp $

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
use Config;

$test = Test::Cmd::Cons->new(string => 'SplitPath');

$test->subdir('subdir');

#
$sub_dir = $test->catfile('sub', 'dir');
$workpath_foo = $test->workpath('foo');
$workpath_subdir_bar = $test->workpath('subdir', 'bar');

#
$SEP = $_is_win32 ? ';' : ':';

#
$test->write(['subdir', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
\$sp_1 = join(' ', SplitPath ".");
\$sp_2 = join(' ', SplitPath "xxx");
\$sp_3 = join(' ', SplitPath "\Q$workpath_foo\E");
\$sp_4 = join(' ', SplitPath "\Q$workpath_subdir_bar\E");
\$sp_5 = join(' ', SplitPath [ "\Q$sub_dir\E", ".", "yyy",
				"\Q$workpath_foo\E",
				"\Q$workpath_subdir_bar\E" ]);
\$sp_6 = join(' ', SplitPath "\Q$sub_dir\E${SEP}.${SEP}yyy${SEP}\Q$workpath_foo\E${SEP}\Q$workpath_subdir_bar\E");
Command \$env 'aaa.out', 'aaa.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'sp_1 = \$sp_1', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'sp_2 = \$sp_2', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'sp_3 = \$sp_3', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'sp_4 = \$sp_4', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'sp_5 = \$sp_5', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'sp_6 = \$sp_6', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

$test->write(['subdir', 'aaa.pl'], <<_EOF_);
$Config{startperl}
print "aaa.pl\\n";
exit(0);
_EOF_

$test->run('chdir' => 'subdir', targets => "."); # expect failure

$test->file_matches(['subdir', 'aaa.out'], <<_EOF_);
\Qaaa.pl\E
sp_1 = \Q.\E
sp_2 = xxx
sp_3 = \Q$workpath_foo\E
sp_4 = bar
sp_5 = \Q$sub_dir\E . yyy \Q$workpath_foo bar\E
sp_6 = \Q$sub_dir\E . yyy \Q$workpath_foo bar\E
_EOF_

#
$test->pass;
__END__
