#! /usr/bin/env perl
#
#	Create a supporting perl sript that reads another perl script,
#	strips comments, and evaluates it.  Create a build perl script
#	that intersperses print lines with comment lines each followed
#	by a single character from \000 to \255.  Use Cons to call the
#	build perl script to write its output to a file.  Check that we
#	saw every line we were supposed to.  Rewrite the build script
#	to append a single print statement.  Re-run Cons.  It should
#	re-generate the output file containing the last printed line;
#	check that it does.  (If not, some character value like ^Z caused
#	Cons to short-circuit its signature calcluation.)
#

# $Id: t0073.t,v 1.2 2000/06/19 16:08:42 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'signature calculation');

# This intermediate evaluation script is necessary because the
# same end-of-file character (^Z) that terminates Cons' signature
# calculation will likely terminate perl's reading of the file
# if we just try to execute the script directly.  The workaround
# is this script which explicitly strips the comments (all of
# the special characters are behind constants) and then eval's
# the resulting contents.
$test->write('eval.pl', <<'_EOF_');
for $file (@ARGV) {
    open(FILE, $file) || die "can not open '$file': $!\n";
    binmode(FILE);
    @lines = <FILE>;
    close(FILE);
    map(s/#.*//, @lines);
    eval join('', @lines);
}
_EOF_

# Generate two arrays:  @print contains all of the print statements
# interspersed with comment lines, one for each character.  @match
# contains all of the output we expect to see if each line is executed.
my $i;
for $i (0 .. 255) {
	push(@print, sprintf "print \"This is line %03o\\n\";", $i);
	push(@print, "#" . chr($i));
	push(@match, sprintf "This is line %03o", $i);
}

# The arrays don't have newlines appended; interpolate them on expansion.
$" = "\n";

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'foo.out', 'foo.pl', qq(
	\Q$^X\E eval.pl %< > %>
);
_EOF_

$test->write('foo.pl', <<_EOF_);
@print
_EOF_

$test->run(targets => ".");

$test->file_matches('foo.out', <<_EOF_);
@match
_EOF_

$test->write('foo.pl', <<_EOF_);
@print
print "This is the last line\\n";
_EOF_

$test->run(targets => ".");

$test->file_matches('foo.out', <<_EOF_);
@match
This is the last line
_EOF_

#
$test->pass;
__END__
