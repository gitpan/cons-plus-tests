#! /usr/bin/env perl
#
#	Specify a 'Command' that executes two a command-list to
#	"build" (in this case, pseudo-install) a file in the local
#	directory.
#

# $Id: t0025.t,v 1.2 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Command');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'foo.pl', 'foo.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', 'tmpfile'); exit 0"
	\Q$^X\E -e "use File::Copy; copy('tmpfile', '%>'); exit 0"
);
_EOF_

$test->write('foo.in', <<_EOF_);
$Config{startperl}
print "This is the foo.in file.\\n";
exit (0);
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo.pl', interpreter => $^X, stdout => <<_EOF_);
This is the foo.in file.
_EOF_

#
$test->pass;
__END__
