package Perl::Analysis::Static::Plugin::Location::Block;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::Block -- Plugin for
  blocks

=head1 DESCRIPTION

This plugin collects blocks.

=head1 ADDITIONAL COLUMN

None.

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

our $VERSION = 1.000;

#sub _get_additional_columns {qw(line col builtin)}

#sub _get_additional_columns_types {qw(INTEGER INTEGER STRING)}

#sub _get_primary_columns {qw(hex_id line col)}

=head2 analyze ($document)

=cut

sub analyze {
	my ( $self, $document ) = @_;
	my @entries;

	# find all blocks
	my $blocks = $document->find('PPI::Structure::Block');

	# return immediately if there are no blocks in the file
	return unless $blocks;

	for my $block (@$blocks) {
		# get location
		my $location = $block->location;
		my $line     = $location->[0];
		my $column   = $location->[2];

		# build entry
		my $entry =
			{ line => $line, col => $column };

		# add entry
		push @entries, $entry;
	}

	# return undef if nothing was found
	return unless @entries;

	# we have a list of blocks, return reference to it
	return \@entries;

}

1;

=head1 AUTHOR

Gregor Goldbach, C<ggoldbach AT cpan DOT org>

=head1 SEE ALSO

L<Perl::Analysis::Static::Plugin>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
