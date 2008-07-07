package Perl::Analysis::Static::Plugin::Location;

=head1 NAME

Perl::Analysis::Static::Plugin::Location -- Plugin for an analysis
	that's unique per location 

=head1 DESCRIPTION

This class provides a base class for all plugins that perform
an analysis that's unique per location. A location tells you in which line
at which column the analysis found the thing.

Deriving classes only have to override the method C<analyze> that's performing
the actual analysis.

FIXME
To change
it's type just override the method C<_get_additional_columns_types>.

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin';

our $VERSION=1.000;

sub _get_additional_columns { qw(line col ) }

sub _get_additional_columns_types { qw(NUMERIC NUMERIC) }

sub _get_primary_columns { qw(hex_id line col) }

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
