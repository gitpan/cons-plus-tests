#! /usr/bin/env perl
#
#	Install a file from one subdirectory to another.
#

# $Id: t0011.t,v 1.2 2000/06/01 22:00:44 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Install');

$test->subdir('src');

#
$workpath_install_foo_pl = $test->workpath('install', 'foo.pl');
$src_Conscript = $test->catfile('src', 'Conscript');

#
$test->write('Construct', <<_EOF_);
Build '$src_Conscript';
_EOF_

$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Install \$env '#install', 'foo.pl';
_EOF_

$test->write(['src', 'foo.pl'], <<_EOF_);
$Config{startperl}
print "Called with arg 0 = '\$0'\n";
_EOF_

$test->run(targets => ".");

$test->execute(prog => $workpath_install_foo_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_foo_pl\E'
_EOF_

#
$test->pass;
__END__
