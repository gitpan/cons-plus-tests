#! /usr/bin/env perl
#
#	Use perl to print all combinations of %[<>0-9](:[df]?)?
#	variables into various files.
#

# $Id: t0036.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '%-variables');

$test->subdir('sub', ['sub', 'dir']);

#
$sub_dir = $test->catfile('sub', 'dir');
$sub_zero = $test->catfile('sub', 'zero');
$sub_zero_out = $test->catfile('sub', 'zero.out');
$sub_dir_right = $test->catfile('sub', 'dir', 'right');
$sub_dir_right_out = $test->catfile('sub', 'dir', 'right.out');

$workdir_right_out = $test->catfile($test->workdir, 'right.out');
$workdir_sub_zero_out = $test->catfile($test->workdir, $sub_zero_out);
$workdir_sub_dir_right_out = $test->catfile($test->workdir, $sub_dir_right_out);

$foo_1 = 'foo.1';
$foo_2 = 'foo.2';
$foo_3 = 'foo.3';
$foo_4 = 'foo.4';
$foo_5 = 'foo.5';
$foo_6 = 'foo.6';
$foo_7 = 'foo.7';
$foo_8 = 'foo.8';
$foo_9 = 'foo.9';
$foo_10 = 'foo.10';
$sub_foo = $test->catfile('sub', 'foo');
$sub_foo_4 = $test->catfile('sub', $foo_4);
$sub_foo_5 = $test->catfile('sub', $foo_5);
$sub_foo_6 = $test->catfile('sub', $foo_6);
$sub_dir_foo = $test->catfile('sub', 'dir', 'foo');
$sub_dir_foo_7 = $test->catfile('sub', 'dir', $foo_7);
$sub_dir_foo_8 = $test->catfile('sub', 'dir', $foo_8);
$sub_dir_foo_9 = $test->catfile('sub', 'dir', $foo_9);

$workdir_foo_1 = $test->catfile($test->workdir, $foo_1);
$workdir_foo_2 = $test->catfile($test->workdir, $foo_2);
$workdir_foo_3 = $test->catfile($test->workdir, $foo_3);
$workdir_sub_foo_4 = $test->catfile($test->workdir, $sub_foo_4);
$workdir_sub_foo_5 = $test->catfile($test->workdir, $sub_foo_5);
$workdir_sub_foo_6 = $test->catfile($test->workdir, $sub_foo_6);
$workdir_sub_dir_foo_7 = $test->catfile($test->workdir, $sub_dir_foo_7);
$workdir_sub_dir_foo_8 = $test->catfile($test->workdir, $sub_dir_foo_8);
$workdir_sub_dir_foo_9 = $test->catfile($test->workdir, $sub_dir_foo_9);
$workdir_foo_10 = $test->catfile($test->workdir, $foo_10);

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
\@deps = qw(
	$foo_1
	$foo_2
	$foo_3
	$sub_foo_4
	$sub_foo_5
	$sub_foo_6
	$sub_dir_foo_7
	$sub_dir_foo_8
	$sub_dir_foo_9
	$foo_10
);
Command \$env 'out_left', \@deps, qq(
	\Q$^X\E -e "print '========== left_bracket', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket is %<', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:b is %<:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:d is %<:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:f is %<:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:s is %<:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:F is %<:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'left_bracket:a is %<:a', \\\\"\\\\n\\\\"" >> %>
);
Command \$env 'right.out', \@deps, qq(
	\Q$^X\E -e "print '========== right_bracket', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket is %>', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:b is %>:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:d is %>:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:f is %>:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:s is %>:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:F is %>:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:a is %>:a', \\\\"\\\\n\\\\"" >> %>
);
Command \$env '$sub_zero_out', \@deps, qq(
	\Q$^X\E -e "print '========== 0', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0 is %0', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:b is %0:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:d is %0:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:f is %0:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:s is %0:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:F is %0:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '0:a is %0:a', \\\\"\\\\n\\\\"" >> %>
);
Command \$env '$sub_dir_right_out', \@deps, qq(
	\Q$^X\E -e "print '========== right_bracket', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket is %>', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:b is %>:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:d is %>:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:f is %>:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:s is %>:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:F is %>:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print 'right_bracket:a is %>:a', \\\\"\\\\n\\\\"" >> %>
);
Command \$env 'out_numbers', \@deps, qq(
	\Q$^X\E -e "print '========== 1', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1 is %1', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:b is %1:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:d is %1:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:f is %1:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:s is %1:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:F is %1:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '1:a is %1:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 2', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2 is %2', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:b is %2:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:d is %2:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:f is %2:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:s is %2:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:F is %2:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '2:a is %2:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 3', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3 is %3', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:b is %3:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:d is %3:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:f is %3:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:s is %3:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:F is %3:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '3:a is %3:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 4', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4 is %4', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:b is %4:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:d is %4:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:f is %4:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:s is %4:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:F is %4:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '4:a is %4:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 5', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5 is %5', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:b is %5:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:d is %5:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:f is %5:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:s is %5:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:F is %5:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '5:a is %5:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 6', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6 is %6', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:b is %6:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:d is %6:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:f is %6:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:s is %6:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:F is %6:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '6:a is %6:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 7', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7 is %7', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:b is %7:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:d is %7:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:f is %7:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:s is %7:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:F is %7:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '7:a is %7:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 8', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8 is %8', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:b is %8:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:d is %8:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:f is %8:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:s is %8:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:F is %8:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '8:a is %8:a', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '========== 9', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9 is %9', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:b is %9:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:d is %9:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:f is %9:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:s is %9:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:F is %9:F', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "print '9:a is %9:a', \\\\"\\\\n\\\\"" >> %>
);
Command \$env 'out_list', \@deps, qq(
	\Q$^X\E -e "print '========== 1 3 5 7 9 left_bracket', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket is %<', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket:b is %<:b', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket:d is %<:d', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket:f is %<:f', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket:s is %<:s', \\\\"\\\\n\\\\"" >> %>
	\Q$^X\E -e "'%1 %3 %5 %7 %9'; print 'after 1 3 5 7 9, left_bracket:F is %<:F', \\\\"\\\\n\\\\"" >> %>
);
_EOF_

$test->write($foo_1, <<_EOF_);
This is the $foo_1 file.
_EOF_

$test->write($foo_2, <<_EOF_);
This is the $foo_2 file.
_EOF_

$test->write($foo_3, <<_EOF_);
This is the $foo_3 file.
_EOF_

$test->write($sub_foo_4, <<_EOF_);
This is the $sub_foo_4 file.
_EOF_

$test->write($sub_foo_5, <<_EOF_);
This is the $sub_foo_5 file.
_EOF_

$test->write($sub_foo_6, <<_EOF_);
This is the $sub_foo_6 file.
_EOF_

$test->write($sub_dir_foo_7, <<_EOF_);
This is the $sub_dir_foo_7 file.
_EOF_

$test->write($sub_dir_foo_8, <<_EOF_);
This is the $sub_dir_foo_8 file.
_EOF_

$test->write($sub_dir_foo_9, <<_EOF_);
This is the $sub_dir_foo_9 file.
_EOF_

$test->write($foo_10, <<_EOF_);
This is the $foo_10 file.
_EOF_

#
$test->run(targets => ".");

$test->file_matches('out_left', <<_EOF_);
========== left_bracket
\Qleft_bracket is $foo_1 $foo_2 $foo_3 $sub_foo_4 $sub_foo_5 $sub_foo_6 $sub_dir_foo_7 $sub_dir_foo_8 $sub_dir_foo_9 $foo_10\E
\Qleft_bracket:b is foo foo foo $sub_foo $sub_foo $sub_foo $sub_dir_foo $sub_dir_foo $sub_dir_foo foo\E
\Qleft_bracket:d is . . . sub sub sub $sub_dir $sub_dir $sub_dir .\E
\Qleft_bracket:f is $foo_1 $foo_2 $foo_3 $foo_4 $foo_5 $foo_6 $foo_7 $foo_8 $foo_9 $foo_10\E
\Qleft_bracket:s is .1 .2 .3 .4 .5 .6 .7 .8 .9 .10\E
\Qleft_bracket:F is foo foo foo foo foo foo foo foo foo foo\E
\Qleft_bracket:a is $workdir_foo_1 $workdir_foo_2 $workdir_foo_3 $workdir_sub_foo_4 $workdir_sub_foo_5 $workdir_sub_foo_6 $workdir_sub_dir_foo_7 $workdir_sub_dir_foo_8 $workdir_sub_dir_foo_9 $workdir_foo_10\E
_EOF_

$test->file_matches('right.out', <<_EOF_);
========== right_bracket
\Qright_bracket is right.out\E
\Qright_bracket:b is right\E
\Qright_bracket:d is .\E
\Qright_bracket:f is right.out\E
\Qright_bracket:s is .out\E
\Qright_bracket:F is right\E
\Qright_bracket:a is $workdir_right_out\E
_EOF_

$test->file_matches($sub_zero_out, <<_EOF_);
========== 0
\Q0 is $sub_zero_out\E
\Q0:b is $sub_zero\E
\Q0:d is sub\E
\Q0:f is zero.out\E
\Q0:s is .out\E
\Q0:F is zero\E
\Q0:a is $workdir_sub_zero_out\E
_EOF_

$test->file_matches($sub_dir_right_out, <<_EOF_);
========== right_bracket
\Qright_bracket is $sub_dir_right_out\E
\Qright_bracket:b is $sub_dir_right\E
\Qright_bracket:d is $sub_dir\E
\Qright_bracket:f is right.out\E
\Qright_bracket:s is .out\E
\Qright_bracket:F is right\E
\Qright_bracket:a is $workdir_sub_dir_right_out\E
_EOF_

$test->file_matches('out_numbers', <<_EOF_);
========== 1
\Q1 is $foo_1\E
\Q1:b is foo\E
\Q1:d is .\E
\Q1:f is $foo_1\E
\Q1:s is .1\E
\Q1:F is foo\E
\Q1:a is $workdir_foo_1\E
========== 2
\Q2 is $foo_2\E
\Q2:b is foo\E
\Q2:d is .\E
\Q2:f is $foo_2\E
\Q2:s is .2\E
\Q2:F is foo\E
\Q2:a is $workdir_foo_2\E
========== 3
\Q3 is $foo_3\E
\Q3:b is foo\E
\Q3:d is .\E
\Q3:f is $foo_3\E
\Q3:s is .3\E
\Q3:F is foo\E
\Q3:a is $workdir_foo_3\E
========== 4
\Q4 is $sub_foo_4\E
\Q4:b is $sub_foo\E
\Q4:d is sub\E
\Q4:f is $foo_4\E
\Q4:s is .4\E
\Q4:F is foo\E
\Q4:a is $workdir_sub_foo_4\E
========== 5
\Q5 is $sub_foo_5\E
\Q5:b is $sub_foo\E
\Q5:d is sub\E
\Q5:f is $foo_5\E
\Q5:s is .5\E
\Q5:F is foo\E
\Q5:a is $workdir_sub_foo_5\E
========== 6
\Q6 is $sub_foo_6\E
\Q6:b is $sub_foo\E
\Q6:d is sub\E
\Q6:f is $foo_6\E
\Q6:s is .6\E
\Q6:F is foo\E
\Q6:a is $workdir_sub_foo_6\E
========== 7
\Q7 is $sub_dir_foo_7\E
\Q7:b is $sub_dir_foo\E
\Q7:d is $sub_dir\E
\Q7:f is $foo_7\E
\Q7:s is .7\E
\Q7:F is foo\E
\Q7:a is $workdir_sub_dir_foo_7\E
========== 8
\Q8 is $sub_dir_foo_8\E
\Q8:b is $sub_dir_foo\E
\Q8:d is $sub_dir\E
\Q8:f is $foo_8\E
\Q8:s is .8\E
\Q8:F is foo\E
\Q8:a is $workdir_sub_dir_foo_8\E
========== 9
\Q9 is $sub_dir_foo_9\E
\Q9:b is $sub_dir_foo\E
\Q9:d is $sub_dir\E
\Q9:f is $foo_9\E
\Q9:s is .9\E
\Q9:F is foo\E
\Q9:a is $workdir_sub_dir_foo_9\E
_EOF_

$test->file_matches('out_list', <<_EOF_);
========== 1 3 5 7 9 left_bracket
\Qafter 1 3 5 7 9, left_bracket is $foo_2 $sub_foo_4 $sub_foo_6 $sub_dir_foo_8 $foo_10\E
\Qafter 1 3 5 7 9, left_bracket:b is foo $sub_foo $sub_foo $sub_dir_foo foo\E
\Qafter 1 3 5 7 9, left_bracket:d is . sub sub $sub_dir .\E
\Qafter 1 3 5 7 9, left_bracket:f is $foo_2 $foo_4 $foo_6 $foo_8 $foo_10\E
\Qafter 1 3 5 7 9, left_bracket:s is .2 .4 .6 .8 .10\E
\Qafter 1 3 5 7 9, left_bracket:F is foo foo foo foo foo\E
_EOF_

#
$test->pass;
__END__
