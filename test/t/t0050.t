#! /usr/bin/env perl
#
#	Create a Construct file and a Conscript file in a subdirectory.
#	The Construct file prints to an output file the result of two
#	FilePath calls, one each to an existent file and a non-existent
#	file.  The Conscript prints to an output file the result of a
#	single FilePath call with two arguments, one each to an
#	existent file and a non-existent file, but returned to an
#	array.  Check the output files.  Rewrite the Construct file
#	so it does FilePath on the subdirectory as an argument to
#	Default; check that cons issues the appropriate warning about
#	improper use of FilePath, but otherwise builds successfully.
#

# $Id: t0050.t,v 1.6 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'FilePath');

$test->subdir('subdir');

#
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_bbb_out = $test->catfile('subdir', 'bbb.out');
$subdir_bbb_pl = $test->catfile('subdir', 'bbb.pl');
$subdir_yyy = $test->catfile('subdir', 'yyy');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Build '$subdir_Conscript';
\$fp_aaa_pl = FilePath 'aaa.pl';
\$fp_xxx = FilePath 'xxx';
Command \$env 'aaa.out', 'aaa.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'fp_aaa_pl = \$fp_aaa_pl', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'fp_xxx = \$fp_xxx', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
Import qw( env );
\@fp_arr = FilePath 'bbb.pl', 'yyy';
Command \$env 'bbb.out', 'bbb.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'fp_arr = \@fp_arr', \\\\"\\\\n\\\\"" >> %>
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

#
$test->run(targets => ".");

$test->file_matches('aaa.out', <<_EOF_);
\Qaaa.pl\E
\Qfp_aaa_pl = aaa.pl\E
\Qfp_xxx = xxx\E
_EOF_

$test->file_matches($subdir_bbb_out, <<_EOF_);
\Qsubdir/bbb.pl\E
\Qfp_arr = $subdir_bbb_pl $subdir_yyy\E
_EOF_

#
$test->run(flags => "-r", targets => ".");
$test->must_not_exist('aaa.out');
$test->must_not_exist($subdir_bbb_out);

#
# Put FilePath before the expansion of $test->cons_env,
# so the line number in the Construct file is constant.
$test->write('Construct', <<_EOF_);
Default ( FilePath 'subdir' );
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Build '$subdir_Conscript';
\$fp_aaa_pl = FilePath 'aaa.pl';
\$fp_xxx = FilePath 'xxx';
Command \$env 'aaa.out', 'aaa.pl', qq(
	\Q$^X\E %< > %>
	\Q$^X\E -e "print 'fp_aaa_pl = \$fp_aaa_pl', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'fp_xxx = \$fp_xxx', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

#
$test->run(targets => "", stderr => <<_EOF_);
\Q${\$test->basename}\E:  Warning:  script::FilePath used to refer to a directory
	at line 1 of Construct.  Use DirPath instead.
_EOF_
$test->must_not_exist('aaa.out');

$test->file_matches($subdir_bbb_out, <<_EOF_);
\Qsubdir/bbb.pl\E
\Qfp_arr = $subdir_bbb_pl $subdir_yyy\E
_EOF_

#
$test->pass;
__END__
