# $Id: Cons.pm,v 1.9 2000/06/19 22:01:30 knight Exp $

# This module should be included in every Cons test.
# Run "perldoc Test::Cmd::Cons" to get at the documentation
# for using this module.

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

package Test::Cmd::Cons;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $_exe $_o $_a $_is_win32);
use Exporter ();

$VERSION = '2.1';
@ISA = qw(Test::Cmd Exporter);

@EXPORT_OK = qw($_exe $_o $_a $_is_win32);

use Config;
use Cwd;
use File::Copy ();
use Test::Cmd;

use vars qw($Cons $Cons_Env);



=head1 NAME

Test::Cmd::Cons - module for testing the Cons software construction utility

=head1 SYNOPSIS

  use Test::Cmd::Cons;

  $test = Test::Cmd::Cons->new(string => 'functionality being tested');

  $test->cons;

  $test->cons_env;
  $test->cons_env('CC => "gcc", AR => 'ar', RANLIB => 'ranlib'");

  $test->cons_env_val('VARIABLE');

  $test->run(chdir => 'subdir', fail => '$? != 0',
		flags => '-x', targets => '.',
		stdout => <<_EOF_, stderr => <<_EOF_);
  standard output
  _EOF_
  error output
  _EOF_

  $test->up_to_date(chdir => 'subdir', flags => '-x', targets => '.');

  $test->execute(prog => 'foo.pl', interpreter => $^X,
		args => '-f arg1 arg2', fail => '$? != 0',
		expect => <<_EOF_);
  expected output
  _EOF_

  $test->subdir('subdir', ...);

  $test->read(\$contents, 'file');
  $test->read(\@lines, 'file');

  $test->write('file', <<_EOF_);
  contents of the file
  _EOF_

  $test->file_matches();

  $test->must_exist('file', ['subdir', 'file'], ...);

  $test->must_not_exist('file', ['subdir', 'file'], ...);

  $test->copy('src_file', 'dst_file');

  $test->sleep($seconds);

  $test->touch('file', ...);

  $test->unlink('file', ...);

  use Test::Cmd::Cons qw($_exe $_o $_a $_is_win32);

=head1 DESCRIPTION

The C<Test::Cmd::Cons> module provides a simple, high-level interface for
writing tests of the Cons software construction utility.

All methods throw exceptions and exit on failure.  This makes it
unnecessary to add explicit checks for return values, making the test
scripts themselves simpler to write and easier to read.

The C<Test::Cmd::Cons> module provides some importable variables:
C<$_exe>, C<$_o>, C<$_a>, C<$_is_win32>.  The first three are respectively,
the values normally available from C<$Config{_exe}> (executable file
suffix), C<$Config{_o}> (object file suffix) and C<$Config{_a}> (library
suffix).  These C<$Config> values, however, are not available prior to
Perl 5.005, so the C<Test::Cmd::Cons> module figures out proper values
via other means, if necessary.  The C<$_is_win32> variable provides
a Perl-version-independent means of testing for whether the current
platform is a Win32 system.

=head1 METHODS

=over 4

=cut

BEGIN {
    if ($] <  5.003) {
	eval("require Win32");
	$_is_win32 = ! $@;
    } else {
	$_is_win32 = $^O eq "MSWin32";
    }

    $Cons = $ENV{CONS} || 'cons';

    $Cons_Env = $ENV{CONSENV};
    if (! $Cons_Env) {
	if ($_is_win32) {
		# Ordinarily, we want to use the default
		# CC, LINK and PREFLIB values in Cons itself.
		# Unfortunately, some of the tests use the
		# cons_env_val method to fetch them for
		# examination, so we need to duplicate them here.
		$Cons_Env = "
			CC => 'cl',
			CCOUTPUT => ' > nul',
			# CCCOM redirects standard output to nul
			# because I can't find *any* way to get the
			# stupid MSVC compiler to *not* print the
			# file name it's compiling.  No command-line
			# option, no environment variable, nada.
			# The extra file name print messes up the
			# output we examine to see if Cons did the
			# right thing in certain circumstances.
			CCCOM	=> '%CC %CFLAGS %_IFLAGS /c %< /Fo%> %CCOUTPUT',
			LINK => 'link',
			# Use the magic, undocumented %_LIBS symbol
			# so specifying libraries via -lfoo works
			# on Win32 systems.
			LINKCOM => '%LINK %LDFLAGS /out:%> %< %_LDIRS %_LIBS',
			PREFLIB => '',
			ENV => {
				INCLUDE => 'C:\\program files\\devstudio\\vc\\include;C:\\program files\\devstudio\\vc\\atl\\include;C:\\program files\\devstudio\\vc\\mfc\\include',
				LIB => 'C:\\program files\\devstudio\\vc\\lib;C:\\program files\\devstudio\\vc\\mfc\\lib',
				MSDEVDIR => 'C:\\Program Files\\DevStudio\\SharedIDE',
				MSDEVINC => 'C:\\Program Files\\DevStudio\\vc\\include',
				PATH => 'C:\\Tools;C:\\WINNT\\system32;C:\\WINNT;C:\\program files\\devstudio\\sharedide\\bin\\ide;C:\\program files\\devstudio\\sharedide\\bin;C:\\program files\\devstudio\\vc\\bin'
			}
			";
	} else {
		# Use our current environment PATH in Cons
		# environments.  Some of the tests invoke Cons,
		# which in turn runs Perl.  This makes sure
		# Cons can execute the perl version being run.
		$Cons_Env = "ENV => {
				PATH => '$ENV{PATH}'
			     },\n";
		$Cons_Env .= "AR => '$ENV{AR}',\n" if $ENV{AR};
		$Cons_Env .= "CC => '$ENV{CC}',\n" if $ENV{CC};
		$Cons_Env .= "RANLIB => '$ENV{RANLIB}',\n" if $ENV{RANLIB};
	}
    }
    $_exe = $Config{_exe};
    $_exe = $Config{exe_ext} if ! defined $_exe;
    $_exe = $_is_win32 ? '.exe' : '' if ! defined $_exe;
    $_o = $Config{_o};
    $_o = $Config{obj_ext}  if ! defined $_o;
    $_o = $_is_win32 ? '.obj' : '.o' if ! defined $_o;
    $_a = $Config{_a};
    $_a = $Config{lib_ext} if ! defined $_a;
    $_a = $_is_win32 ? '.lib' : '.a' if ! defined $_a;
}



=item C<new>

Creates a new Cons test environment object.  Any arguments are
keyword-value pairs that are passed through to the construct method
for the base class from which we inherit our methods (typically the
C<Test::Cmd> class).  In the normal case, this need only be the string
describing the functionality being tested:

    $test = Test::Cmd::Cons->new(string => 'cool new feature');

Creates a temporary working directory for the test environment and
changes directory to it.

The Cons script under test will be passed to perl, with the directory
from which it was invoked appended with C<-I>, allowing Cons to use
modules installed in the current directory.

Exits NO RESULT if the object can not be created, the temporary working
directory can not be created, or the current directory cannot be changed
to the temporary working directory.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $cwd = Cwd::cwd();
    my $test = $class->SUPER::new('prog' => $Cons,
				'interpreter' => "$^X -I. -I$cwd",
				'workdir' => '',
				@_);
    $class->SUPER::no_result(! $test, undef, 1);
    my $ret = chdir $test->workdir;
    $test->no_result(! $ret, undef, 1);
    bless($test, $class);
}



=item C<cons>

Returns the Cons program to be executed for the specified test
environment, optionally setting it to the specified argument.

=cut

sub cons {
    my $self = shift;
    my $cons = shift;
    $Cons = $cons if $cons;
    $Cons;
}



=item C<cons_env>

Returns the string representation of the Cons environment for the
specified test environment, optionally setting it to the specified
argument.  Typically used to interpolate the Cons environment
into a Construct or Conscript file:

    $test->write('Construct', <<_EOF_);
    \$Env = new cons ( ${\$test->cons_env} );
    _EOF_

=cut

sub cons_env {
    my $self = shift;
    my $cons_env = shift;
    $Cons_Env = $cons_env if $cons_env;
    $Cons_Env;
}



=item C<cons_env_val>

Fetches a specified value from the Cons environment for the specified
test environment.  Typically used to fetch the current compiler, linker,
flags, or some other variable:

    $CC = $test->cons_env_val('CC');

=cut

sub cons_env_val {
    my $self = shift;
    my $val = shift;
    my %env;
    eval "%env = ( ${\$self->cons_env} );";
    $env{$val};
}



sub _fail_match_show {
    my($self, $stream, $expected, $actual) = @_;
    $self->fail(! $self->match($actual, $expected)
		=> sub {print STDERR "Expected $stream =====\n",
					ref $expected ? @$expected : $expected,
					"Actual $stream =====\n",
					ref $actual ? @$actual : $actual},
		2);
}



=item C<run>

Runs a test on Cons, checking that the test succeeded.  Arguments are
keyword-value pairs that affect the manner in which Cons is executed or
the results are evaluated.

    chdir => 'subdir'
    fail => 'failure condition'	# default is '$? != 0'
    flags => 'Cons flags'
    stderr => 'expected error output'
    stdout => 'expected standard output'
    targets => 'targets to build'

The test fails if:

  --  The specified failure condition is met.  The default failure
      condition is '$? != 0', i.e. Cons exits unsuccesfully.  A
      not-uncommon alternative is:

	  $test->run(fail => '$? == 0');	# expect failure

      when testing how Cons handles errors.

  --  Actual standard output does not match expected standard output
      (if any).  The expected standard output is an array of lines or
      a scalar which will be split on newlines.  Each expected line
      is a regular expression to match against the corresponding line
      in the file:

	  $test->run(stdout => <<_EOF_);
	  Multiple (line|lines)?
	  containing \Q$^X\E regular expressions
	  _EOF_

  --  Actual error output does not match expected error output (if any).
      The expected error output is an array of lines or a scalar which
      will be split on newlines.  Each expected line is a regular
      expression to match against the corresponding line in the file:

	  $test->run(stderr => <<_EOF_);
	  Multiple (line|lines)?
	  containing \Q$^X\E regular expressions
	  _EOF_

=cut

sub run {
    my $self = shift;
    my %args = @_;
    my $cmd = $args{'args'};
    if (! $cmd) {
	$cmd = $args{'targets'};
	$cmd = "$args{'flags'} $cmd" if $args{'flags'};
    }
    $self->SUPER::run(@_, args => $cmd);
    my $cond = $args{'fail'} || '$? != 0';
    $self->fail(eval $cond
		=> sub {print STDERR $self->stdout, $self->stderr},
		1);
    if (defined $args{'stdout'}) {
	my @stdout = $self->stdout;
	$self->_fail_match_show('STDOUT', $args{'stdout'}, \@stdout);
    }
    if (defined $args{'stderr'}) {
	my @stderr = $self->stderr;
	$self->_fail_match_show('STDERR', $args{'stderr'}, \@stderr);
    }
}



=item C<up_to_date>

Runs Cons, specifically checking to make sure that the specified targets
are already up-to-date, and nothing was rebuilt.  Takes the following
keyword-value argument pairs:

    chdir => 'subdir'
    flags => 'Cons flags',
    targets => 'targets to build'

The test fails if:

    Cons exits with an error (non-zero) status
    Cons reports anything being rebuilt
    Cons generates any error output

=cut

sub up_to_date {
    my $self = shift;
    my %args = @_;
    my @expect;
    foreach (split(/\s+/, $args{'targets'})) {
	my $invoke = $self->SUPER::basename;
	push @expect, "$invoke: \"$_\" is up-to-date.\n"
    }

    my $cmd = $args{'targets'};
    $cmd = "$args{'flags'} $cmd" if $args{'flags'};
    $self->run(@_, args => $cmd);
    $self->fail($? != 0 => sub {print $self->stderr}, 1);
    my $expect = join('', @expect);
    $self->fail($expect ne $self->stdout
		=> sub {print STDERR "Expected STDOUT ====\n",
				$expect,
				"Actual STDOUT =====\n",
				$self->stdout},
		1);
    $self->fail($self->stderr ne ''
		=> sub {print STDERR "Unexpected STDERR =====\n",
				$self->stderr},
		1);
}



=item C<execute>

Executes a program or script other than the Cons under test (typically
an executable built by the Cons invocation we're testing).

    args => 'command line arguments'
    fail => 'failure condition'	# default is '$? != 0'
    interpreter => 'prog_interpreter'
    prog => 'progam_to_execute'
    stderr => 'expected error output'
    stdout => 'expected standard output'

The execution fails if:

  --  The specified failure condition is met.  The default failure
      condition is '$? != 0', i.e. the program exits unsuccesfully.

  --  Actual standard output does not match expected standard output
      (if any).  The expected output is an array of lines or a scalar
      which will be split on newlines.  Each expected line is a regular
      expression to match against the corresponding line in the file:

	  $test->run(stdout => <<_EOF_);
	  Multiple (line|lines)?
	  containing \Q$^X\E regular expressions
	  _EOF_

  --  Actual error output does not match expected error output (if any).
      The expected error output is an array of lines or a scalar which
      will be split on newlines.  Each expected line is a regular
      expression to match against the corresponding line in the file:

	  $test->run(stderr => <<_EOF_);
	  Multiple (line|lines)?
	  containing \Q$^X\E regular expressions
	  _EOF_

=cut

sub execute {
    my $self = shift;
    my %args = @_;
    if (! $self->file_name_is_absolute($args{'prog'})) {
	$args{'prog'} = $self->catfile($self->here, $args{'prog'});
    }
    $self->SUPER::run(@_, prog => $args{'prog'});
    my $cond = $args{'fail'} || '$? != 0';
    $self->fail(eval $cond
		=> sub {print STDERR $self->stdout, $self->stderr},
		1);
    if (defined $args{'stdout'}) {
	my @stdout = $self->stdout;
	$self->_fail_match_show('STDOUT', $args{'stdout'}, \@stdout);
    }
    if (defined $args{'stderr'}) {
	my @stderr = $self->stderr;
	$self->_fail_match_show('STDERR', $args{'stderr'}, \@stderr);
    }
}



=item C<subdir>

Creates one or more subdirectories in the temporary working directory.
Exits NO RESULT if the number of subdirectories actually created does
not match the number expected.  For compatibility with its superclass
method, returns the number of subdirectories actually created.

=cut

sub subdir {
    my $self = shift;
    my $expected = @_;
    my $ret = $self->SUPER::subdir(@_);
    $self->no_result($expected != $ret,
		=> sub {print STDERR "could not create subdirectories: $!\n"},
		1);
    return $ret;
}



=item C<read>

Reads the contents of a file, depositing the contents in the destination
referred to by the first argument (a scalar or array reference).  If the
file name is not an absolute path name, it is relative to the temporary
working directory.  Exits NO RESULT if the file could not be read for
any reason.  For compatibility with its superclass method, returns TRUE
on success.

=cut

sub read {
    my $self = shift;
    my $destref = shift;
    my $ret = $self->SUPER::read($destref, @_);
    $self->no_result(! $ret
		=> sub {print STDERR "could not read file contents: $!\n"},
		1);
    return 1;
}



=item C<write>

Writes a file with the specified contents.  If the file name is not an
absolute path name, it is relative to the temporary working directory.
Exits NO RESULT if there were any errors writing the file.
For compatibility with its superclass method, returns TRUE on success.

    $test->write('file', <<_EOF_);
    contents of the file
    _EOF_

=cut

sub write {
    my $self = shift;
    my $file = shift; # the file to write to
    my $ret = $self->SUPER::write($file, @_);
    $self->no_result(! $ret
		=> sub {print STDERR "could not write $file: $!\n"},
		1);
    return 1;
}



=item C<file_matches>

Matches the contents of the specified file (first argument) against the
expected contents.  The expected contents are an array of lines or a
scalar which will be split on newlines.  Each expected line is a regular
expression to match against the corresponding line in the file:

    $test->file_matches('file', <<_EOF_);
    The (1st|first) line\.
    The (2nd|second) line\.
    _EOF_

The expe

=cut

sub file_matches {
    my($self, $file, $regexes) = @_;
    my @lines;
    my $ret = $self->SUPER::read(\@lines, $file);
    $self->no_result(! $ret
		=> sub {print STDERR "could not read file contents: $!\n"},
		1);
    $self->fail(! $self->match(\@lines, $regexes)
		=> sub {print STDERR "Expected contents of $file =====\n",
					ref $regexes ? @$regexes : $regexes,
					"Actual contents of $file =====\n",
					@lines},
		1);
}



=item C<must_exist>

Ensures that the specified files must exist.  Files may be specified as
an array reference of directory components, in which case the pathname
will be constructed by concatenating them.  Exits FAILED if any of the
files does not exist.

=cut

sub must_exist {
    my $self = shift;
    map(ref $_ ? $self->catfile(@$_) : $_, @_);
    my @missing = grep(! -e $_, @_);
    $self->fail(0 + @missing => sub {print STDERR "Files are missing: @missing\n"}, 1);
}



=item C<must_not_exist>

Ensures that the specified files must not exist.  Files may be specified
as an array reference of directory components, in which case the pathname
will be constructed by concatenating them.  Exits FAILED if any of the
files exists.

=cut

sub must_not_exist {
    my $self = shift;
    map(ref $_ ? $self->catfile(@$_) : $_, @_);
    my @exist = grep(-e $_, @_);
    $self->fail(0 + @exist => sub {print STDERR "Unexpected files exist: @exist\n"}, 1);
}



=item C<copy>

Copies a file from the source (first argument) to the destination
(second argument).  Exits NO RESULT if the file could  not be copied
for any reason.

=cut

sub copy {
    my($self, $src, $dest) = @_;
    my $ret = File::Copy::copy($src, $dest);
    $self->no_result(! $ret
		=> sub {print STDERR "Could not copy $src to $dest: $!\n"},
		1);
}



=item C<sleep>

Sleeps at least the specified number of seconds.  Sleeping more seconds
is all right.  Exits NO RESULT if the time slept was less than specified.

=cut

sub sleep {
    my($self, $seconds) = @_;
    my $ret = CORE::sleep($seconds);
    $self->no_result($ret < $seconds,
		=> sub {print STDERR "Only slept $ret seconds\n"},
		1);
}



=item C<touch>

Updates the access and modification times of the specified files.
Exits NO RESULT if any file could not be modified for any reason.

=cut

sub touch {
    my $self = shift;
    my $time = shift;
    my $expected = @_;
    my $ret = CORE::utime($time, $time, @_);
    $self->no_result($expected != $ret,
		=> sub {print STDERR "could not touch files: $!\n"},
		1);
}



=item C<unlink>

Removes the specified files.  Exits NO RESULT if any file could not be
removed for any reason.

=cut

sub unlink {
    my $self = shift;
    my @not_removed;
    my $file;
    foreach $file (@_) {
	if (! CORE::unlink($file)) {
	    push @not_removed, $file;
	}
    }
    $self->no_result(@not_removed != 0,
		=> sub {print STDERR "Could not unlink: @not_removed: $!\n"},
		1);
}



1;
__END__

=back

=head1 ENVIRONMENT

The C<Test::Cmd::Cons> module uses the following environment variables:

=over 4

=item C<CONS>

The Cons script under test.  This may be an absolute or relative path.
The script will be fed to perl and need not have execute permissions set.

=item C<CONSENV>

The Cons environment to use for tests.  This should be a string that will
be interpreted as a hash specifying the values for the local compiler,
linker, flags, etc., to be used for the tests:

	$ export CONSENV="CC => 'gcc', AR => 'ar', LINK => 'ld'"
	$ perl cons-test.pl

=back

The Test::Cmd::Cons module also uses the
C<PRESERVE>,
C<PRESERVE_FAIL>,
C<PRESERVE_NO_RESULT>,
and C<PRESERVE_PASS>
environment variables from the C<Test::Cmd> module.
See the C<Test::Cmd> documentation for details.

=head1 SEE ALSO

perl(1), Test::Cmd(3).

=head1 AUTHOR

Steven Knight, knight@baldmt.com

=head1 ACKNOWLEDGEMENTS

Thanks to Greg Spencer for the inspiration to create this package and
to rewrite all of the cons-test scripts in Perl.

The general idea of testing Cons in this way, as well as the test
reporting of the C<pass>, C<fail> and C<no_result> methods, come from the
testing framework invented by Peter Miller for his Aegis project change
supervisor.  Aegis is an excellent bit of work which integrates creation
and execution of regression tests into the software development process.
Information about Aegis is available at:

	http://www.tip.net.au/~millerp/aegis.html

=cut
