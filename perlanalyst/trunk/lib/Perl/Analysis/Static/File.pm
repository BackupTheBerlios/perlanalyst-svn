package Perl::Analysis::Static::File;

=head1 NAME

Perl::Analysis::Static:::File - A local file to analyze

=head1 DESCRIPTION

This class provides objects that link files on the local filesystem to
the main analysis table via their document C<hex_id> (see L<PPI::Document>)

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, this class has
the following additional methods.

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::DBI';

use Carp;
use PPI::Document;

use Perl::Analysis::Static::Log qw(message debug);

our $VERSION = 1.000;

=head2 path

The C<path> accessor returns a string which contains the non-relative file
path on the local system.

=head2 checked

The C<checked> accessor returns the Unix epoch time for when the C<hex_id>
was last checked for this file.

=head2 hex_id

In the L<Perl::Analysis::Static::Analysis> system all documents are identified by the
hexidecimal MD5 value for their newline-localized contents.

The C<hex_id> accessor returns this id for the file.

=cut

Perl::Analysis::Static::File->table( 'files' );
Perl::Analysis::Static::File->columns( Essential =>
	'path',    # Absolute local filesystem path - '/foo/bar/baz.pm'
	'checked', # UNIX epoch time last checked   - '1128495103'
	'hex_id',  # Document MD5 Identifier        - 'abcdef1234567890'
	);

# Add custom deletion cascade
Perl::Analysis::Static::File->add_trigger(
	before_delete => sub { $_[0]->before_delete },
	);
	
sub before_delete {
	my $self = shift;

	if ( $self->search( hex_id => $self->hex_id )->count == 1 ) {
		# We are the last file with this hex_id.
		# Remove any analysis that were accumulated.
		warn 'DELETE: TODO';
	}

	1;
}


=head2 Document

The C<Document> method provides a convenient shortcut which will
load the L<PPI::Document> object for the file.

Returns a L<PPI::Object> or dies on error.

=cut

sub Document {
	my $self = shift;
	my $path = $self->path();

	# create document object from file
	my $document = PPI::Document->new( $path )
		or croak("failed to load Perl document '$path'");
		
	return $document;
}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static>, L<PPI>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
