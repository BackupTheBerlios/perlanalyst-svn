package Perl::Analysis::Static::Log;

=head1 NAME

Perl::Analysis::Static::Log - Logging tools

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter);

our $VERSION = 1.000;
our @EXPORT_OK=qw(set_debug debug message);

{
	my $debug;

=head2 set_debug ()

Sets the debug flag. 

=cut

	sub set_debug {
		$debug = 1;
	}

=head2 debug ($message)

Prints message only if debug flag is set.

=cut

	sub debug {
		my ($message) = @_;
		# don't log if debug flag isn't set
		return unless $debug;
		message($message);
	}
}

=head2 message ($message)

Print message.

=cut

sub message {
	my ($message) = @_;

	print $message."\n";	
}

1;



=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

