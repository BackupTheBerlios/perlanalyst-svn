package Perl::Analysis::Static::Plugin::Location::Package;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::Package -- Plugin for
  package statements

=head1 DESCRIPTION

This plugin collects package statements.

=head1 ADDITIONAL COLUMN

=over

=item package (STRING)

Name of the package declared.

=back

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

our $VERSION = 1.000;

# FIXME inherit
sub _get_additional_columns { qw(line col package) }

# FIXME inherit
sub _get_additional_columns_types { qw(INTEGER INTEGER STRING) }

=head2 analyze ($document)

Find all PPI::Statement::Package elements. The second significant
child is the package name.

=cut

sub analyze {
	my ( $self, $document ) = @_;
	my @entries;

	# find package statements
	my $statements = $document->find('PPI::Statement::Package');

	# return immediately if there are none of these
	return unless $statements;

	for my $statement (@$statements) {

		# get location
		my $location = $statement->location;
		my $line     = $location->[0];
		my $column   = $location->[2];

		# get significant children
		my @schildren = $statement->schildren();

		# name of the package is the second child
		my $package = $schildren[1];

		# build entry
		my $entry = { line => $line, col => $column, package => $package };

		# add entry
		push @entries, $entry;
	}

	# return undef if nothing was found
	return unless @entries;

	# we have a list of packages, return reference to it
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

