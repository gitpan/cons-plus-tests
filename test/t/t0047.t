#! /usr/bin/env perl
#
#	Define a Construct file that (using Command) creates three
#	derived files from perl scripts.  The second perl
#	script exits 1 (error).  Execute Cons; check that the Cons
#	exit code indicates an error, and that the third derived
#	file was NOT created (i.e., the build stopped at the
#	second file).  Replace the second perl script with one
#	that works.  Execute Cons again.  Check that only the
#	second and third files were created.
#

# $Id: t0047.t,v 1.2 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'rebuild after single-command Command error');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'aaa', 'aaa.pl', qq(
	\Q$^X\E %< > %>
);
Command \$env 'bbb', 'bbb.pl', qq(
	\Q$^X\E %< > %>
);
Command \$env 'ccc', 'ccc.pl', qq(
	\Q$^X\E %< > %>
);
_EOF_

$test->write('aaa.pl', <<_EOF_);
$Config{startperl}
print "This is the aaa.pl file.\\n";
exit(0);
_EOF_

$test->write('bbb.pl', <<_EOF_);
$Config{startperl}
exit(1);	# ERROR EXIT
_EOF_

$test->write('ccc.pl', <<_EOF_);
$Config{startperl}
print "This is the ccc.pl file.\\n";
exit(0);
_EOF_

$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist('ccc');

$test->write('bbb.pl', <<_EOF_);
$Config{startperl}
print "This is the bbb.pl file.\\n";
exit(0);
_EOF_

#
$test->run(targets => ".", stdout => <<_EOF_, stderr => '');
\Q$^X\E bbb.pl > bbb
\Q$^X\E ccc.pl > ccc
_EOF_

#
$test->pass;
__END__
