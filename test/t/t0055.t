#! /usr/bin/env perl
#
#	Create a Construct file with two Commands, one single-line
#	and one multi-line, that each pseudo-install a file.  Make
#	sure it builds all right.  Recreate the Construct file with
#	the single-line Command and one of the lines in the multi-line
#	Command prefixed "@ ".  Rebuild and examine the build output
#	to verify that the @-lines are suppressed.
#

# $Id: t0055.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '@ suppression');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'foo.pl', 'foo.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', '%>'); exit 0"
);
Command \$env 'bar.pl', 'bar.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', 'tmp1'); exit 0"
	\Q$^X\E -e "use File::Copy; copy('tmp1', 'tmp2'); exit 0"
	\Q$^X\E -e "use File::Copy; copy('tmp2', '%>'); exit 0"
);
_EOF_

$test->write('foo.in', <<_EOF_);
$Config{startperl}
print "This is the foo.in file.\\n";
exit (0);
_EOF_

$test->write('bar.in', <<_EOF_);
$Config{startperl}
print "This is the bar.in file.\\n";
exit (0);
_EOF_

#
$test->run(targets => ".", stdout => <<_EOF_);
\Q$^X -e "use File::Copy; copy('bar.in', 'tmp1'); exit 0"\E
\Q$^X -e "use File::Copy; copy('tmp1', 'tmp2'); exit 0"\E
\Q$^X -e "use File::Copy; copy('tmp2', 'bar.pl'); exit 0"\E
\Q$^X -e "use File::Copy; copy('foo.in', 'foo.pl'); exit 0"\E
_EOF_

$test->execute(prog => 'foo.pl', interpreter => $^X, stdout => <<_EOF_);
This is the foo.in file.
_EOF_

$test->run(flags => '-r', targets => ".");

$test->must_not_exist('foo.pl', 'bar.pl');

$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'foo.pl', 'foo.in', qq(
	@ \Q$^X\E -e "use File::Copy; copy('%<', '%>'); exit 0"
);
Command \$env 'bar.pl', 'bar.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', 'tmp1'); exit 0"
	@ \Q$^X\E -e "use File::Copy; copy('tmp1', 'tmp2'); exit 0"
	\Q$^X\E -e "use File::Copy; copy('tmp2', '%>'); exit 0"
);
_EOF_

$test->run(targets => ".", stdout => <<_EOF_);
\Q$^X -e "use File::Copy; copy('bar.in', 'tmp1'); exit 0"\E
\Q$^X -e "use File::Copy; copy('tmp2', 'bar.pl'); exit 0"\E
_EOF_

#
$test->pass;
__END__
