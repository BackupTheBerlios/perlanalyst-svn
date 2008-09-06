package Perl::Analysis::Static::Plugin::Location;

=head1 NAME

Perl::Analysis::Static::Plugin::Location -- Plugin for an analysis
	that's unique per location 

=head1 DESCRIPTION

This class provides a base class for all plugins that perform
an analysis that's unique per location. A location tells you in which line
at which column the analysis found the thing.

This base class basically just tells the system that the primary key consists
of hex_id, line and column. The C<rows_for_file()> method returns the rows
ordered by line and column.

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin';
use Carp;

our $VERSION=1.000;

# line and column are key columns
sub _get_additional_columns { qw(line col ) }

# both are numeric
sub _get_additional_columns_types { qw(NUMERIC NUMERIC) }

# this is the primary key
sub _get_primary_columns { qw(hex_id line col) }

=head2 rows_for_file ($hex_id)

Get all rows for the file with this hex_id. The rows are ordered by
line and column.

Returns undef if there are no rows, reference to list of rows otherwise.

Overrides the method of class L<Perl::Analysis::Static::Plugin>.

=cut

sub rows_for_file {
	my ($self, $hex_id)=@_;

	croak "Argument error: Need hex_id" unless $hex_id;

	my @rows=$self->retrieve_all(qq{hex_id = $hex_id order by line,col});
	
	return unless @rows;
	
	return \@rows;
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
