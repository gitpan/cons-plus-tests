#! /usr/bin/env perl
#
# cons-test
#
#	Run the cons regression test suite.
#

# $Id: cons-test.pl,v 1.8 2000/06/27 02:50:50 knight Exp $

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

use File::Basename;
require "getopts.pl";

($My_Name = $0) =~ s(.*/)();	# basename
$Usage = "Usage:  $My_Name [-q] [-d dir] [-x script] [test_script ...]
	-d dir		search for tests in specified dir
	-q		quiet, supress warnings about undefined variables
	-x script	test specified script, not default 'cons' or 'cons.pl'";

&Getopts('d:qx:') || die "$Usage\n";

$dir = (defined($opt_d)) ? $opt_d : -d 't' ? 't' : '.';

sub env_warn {
    #
    # Make sure that platforms that don't have cc in the regular path
    # can define it. Otherwise, define it as standard 'cc'.
    #
    if (! defined($ENV{'CC'})) {
	warn "$My_Name:  CC not defined! using 'cc'\n";
	$ENV{'CC'} = 'cc';
    }

    if (! defined($ENV{'AR'})) {
	warn "$My_Name:  AR not defined! using 'ar'\n";
	$ENV{'AR'} = 'ar';
    }

    if (! defined($ENV{'RANLIB'})) {
	warn "$My_Name:  RANLIB not defined! using 'ranlib'\n";
	$ENV{'RANLIB'} = 'ranlib';
    }
}

if (defined($opt_x)) {
    $Cons = $opt_x;
    if (! -f $Cons) {
	print STDERR "$My_Name:  The specified '$Cons' script does not exist.\n";
	print STDERR "\tCreate it, or use -x to specify some other script.\n";
	print STDERR "$Usage\n";
	exit 1;
    }
} else {
    foreach ('cons', 'cons.pl') {
	$Cons = $_, last if -f;
    }
    if (! $Cons) {
	print STDERR "$My_Name:  There is no 'cons' or 'cons.pl' script in the current directory.\n";
	print STDERR "\tCreate one, or use -x to specify some other script.\n";
	print STDERR "$Usage\n";
	exit 1;
    }
    print "Using the '$Cons' script.\n" unless $opt_q;
}

if ($] <  5.003) {
    eval("require Win32");
    $use_waitpid = $@;
} else {
    $use_waitpid = $^O ne "MSWin32";
}

$ENV{CONS} = $Cons;

my $pass = 0;
my @fail;

sub report {
    my($sofar) = @_;
    if (@fail == 0) {
	print "$My_Name:  '$Cons' passed all $pass tests$sofar.\n";
    } else {
	printf "$My_Name:  '$Cons' passed $pass tests, failed %d$sofar:\n", scalar @fail;
	print "\t\t", join("\n\t\t", @fail), "\n";
    }
}

my $child_pid;

sub handler {
    my($sig) = @_;
    waitpid($child_pid, 0) if $use_waitpid;
    print "$My_Name:  Caught SIG$sig; exiting.\n";
    print "\n";
    &report(' so far');
    exit (1);
}

$SIG{'HUP'} = \&handler;
$SIG{'INT'} = \&handler;
$SIG{'QUIT'} = \&handler;
$SIG{'TERM'} = \&handler;

#    my(@list) = sort grep(/^t[0-9]+a.sh$/, readdir(DIR));

my %suffix_map = (
	'.t'	=> "$^X -w",
	'.pl'	=> "$^X -w",
	'.sh'	=> 'sh',
);

sub fetch_tests {
    opendir(DIR, $_[0]) || die "$My_Name: cannot open '$_[0]': $!\n";
    my(@list) = sort grep(/^t[0-9]+\.t$/, readdir(DIR));
    closedir(DIR);
    return @list;
}

@ARGV = &fetch_tests($dir) if ! @ARGV;

$| = 1;	# flush print

$prefix = ($dir eq '.') ? '' : "$dir/";

$first = 1;

while (@ARGV) {
    $test = shift @ARGV;
    if ($test =~ m/([^=]*)=(.*)/o) {
	$ENV{$1} = $2;
	if (! @ARGV && @fail == 0 && $pass == 0) {
	    @ARGV = &fetch_tests($dir);
	}
	next;
    }
    if ($first) {
	&env_warn unless $opt_q;
	$first = undef;
    }
    my ($name, $path, $suffix) = fileparse($test, keys %suffix_map);
    my($cmd) = "$suffix_map{$suffix} $prefix$test";
    print "$My_Name:  $cmd\n";
    $child_pid = open(PIPE, "|$cmd");
    if (! defined($child_pid)) {
	print "Unable to start '$cmd': $!\n";
	&report(' so far');
	exit (1);
    }
    waitpid($child_pid, 0) if $use_waitpid;
    $exit = $?;
    if ($exit) {
	push(@fail, $test);
    } else {
	$pass++;
    }
    close(PIPE);
}

print "\n";
&report();

exit @fail;
