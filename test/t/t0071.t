#! /usr/bin/env perl
#
#	Create a build script that prints a file, with a very simple
#	include-file  capability.  Create a Construct file that uses
#	this build script (via Command) to create two output files from
#	separate input files.  Use QuickScan to associate code references
#	that look for the same include-file strings with the appropriate
#	files, including one recursive-include case.  Run Cons; look for
#	proper output.	Update the file that both input files include;
#	run Cons; look for proper output.  Update one of the other
#	included files; run Cons; look for proper output.  Update the
#	last included file; run Cons; look for proper output.
#

# $Id: t0071.t,v 1.4 2000/06/10 04:09:21 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'QuickScan');

$test->subdir('one', 'two');

#

# A builder script that implements a simple include-file capability
# with -I support for a search path.
$test->write('build.pl', <<_EOF_);
$Config{startperl}
use File::Spec;

while (\@ARGV) {
	\$arg = shift \@ARGV;
	if (\$arg =~ s/^-I//) {
		\$arg = shift \@ARGV if ! \$arg;
		push \@dirs, \$arg;
	} else {
		unshift \@ARGV, \$arg;
		last;
	}
}

push \@dirs, '.';

sub file {
	my(\$file) = \@_;
	local *FILE;
	my \$dir;
	foreach \$dir (\@dirs) {
		last if open(FILE, File::Spec->catfile(\$dir, \$file));
	}
	while (<FILE>) {
		if (s/^\\s*include\\s+//) {
			my \@files = split /\\s+/;
			my \$f;
			foreach \$f (\@files) {
				file(\$f);
			}
		}
		print;
	}
	close(FILE);
}

my \$file;
foreach \$file (\@ARGV) {
	file(\$file);
}
_EOF_

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
QuickScan \$env sub {return \$1 if /include\\s+(\\S+)/}, 'foo.in';
Command \$env 'foo', 'foo.in', qq(
	\Q$^X\E build.pl %< > %>
);
sub myscan { /\\b\\S*?\\.in\\b/g }
\$env->QuickScan(\\\&myscan, 'bar.in', 'one:two');
\$env->QuickScan(\\\&myscan, 'one/ggg.in', 'one:two');
Command \$env 'bar', 'bar.in', qq(
	\Q$^X\E build.pl -I one -I two %< > %>
);
_EOF_

$test->write('foo.in', <<_EOF_);
foo 1
include fff.in
foo 3
_EOF_

$test->write('bar.in', <<_EOF_);
include fff.in
bar 2
include ggg.in iii.in
_EOF_

#
$test->write('fff.in', <<_EOF_);
fff 1
fff 2
_EOF_

$test->write(['one', 'ggg.in'], <<_EOF_);
one/ggg 1
include hhh.in
_EOF_

$test->write(['two', 'hhh.in'], <<_EOF_);
two/hhh 1
two/hhh 2
two/hhh 3
_EOF_

$test->write('iii.in', <<_EOF_);
iii 1
_EOF_

$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo 1
fff 1
fff 2
foo 3
_EOF_

$test->file_matches('bar', <<_EOF_);
fff 1
fff 2
bar 2
one/ggg 1
two/hhh 1
two/hhh 2
two/hhh 3
iii 1
_EOF_

#
$test->write('fff.in', <<_EOF_);
fff X
fff Y
fff Z
_EOF_

$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo 1
fff X
fff Y
fff Z
foo 3
_EOF_

$test->file_matches('bar', <<_EOF_);
fff X
fff Y
fff Z
bar 2
one/ggg 1
two/hhh 1
two/hhh 2
two/hhh 3
iii 1
_EOF_

#
$test->write(['one', 'ggg.in'], <<_EOF_);
one/ggg !
include hhh.in
_EOF_

$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo 1
fff X
fff Y
fff Z
foo 3
_EOF_

$test->file_matches('bar', <<_EOF_);
fff X
fff Y
fff Z
bar 2
one/ggg !
two/hhh 1
two/hhh 2
two/hhh 3
iii 1
_EOF_

#
$test->write(['two', 'hhh.in'], <<_EOF_);
two/hhh A
_EOF_

$test->run(targets => ".");

$test->file_matches('foo', <<_EOF_);
foo 1
fff X
fff Y
fff Z
foo 3
_EOF_

$test->file_matches('bar', <<_EOF_);
fff X
fff Y
fff Z
bar 2
one/ggg !
two/hhh A
iii 1
_EOF_

#
$test->pass;
__END__
