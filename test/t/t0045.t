#! /usr/bin/env perl
#
#	Define a Construct file that (using Command) creates a
#	derived file from a perl script.  The perl script
#	exits 1 (error).  Execute Cons; check that the Cons
#	exit status indicates an error.
#

# $Id: t0045.t,v 1.2 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'error exit status');

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Command \$env 'aaa', 'aaa.pl', qq(
	\Q$^X\E %< > %>
);
_EOF_

$test->write('aaa.pl', <<'_EOF_');
$Config{startperl}
exit(1);		# ERROR EXIT
_EOF_

$test->run(targets => ".", fail => '$? == 0'); # expect failure

#
$test->pass;
__END__
