package Perl::Analysis::Static::Plugin::OncePerFile;

=head1 NAME

Perl::Analysis::Static::Plugin::OncePerlFile -- Plugin for an analysis
	that's done once per file 

=head1 DESCRIPTION

This class provides a base class for all plugins that perform
an analysis once per file.

Deriving classes only have to override the method C<analyze> that's performing
the actual analysis. That method ought to return a single value, it
will be stored in a column C<value> of type integer. To change
it's type just override the method C<_get_additional_columns_types>.

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin';

our $VERSION=1.000;

sub _get_additional_columns { ('value') }

sub _get_additional_columns_types { ('INTEGER') }

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
