package Perl::Analysis::Static::Plugin::OncePerFile::One;

=head1 NAME

  Perl::Analysis::Static::Plugin::OncePerlFile::One -- example plugin
    returning 1

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::OncePerFile';

our $VERSION=1.000;

=head2 analyze ($document)

Main method for the analysis. The only argument is an instance
of the class L<PPI::Document> which represents the document to
analyze. This method may analyze the document in any way it wants
to.

Results: Reference to hash with key named value set to 1. To change
it's type just override the method C<_get_additional_columns_types>.

=cut

sub analyze {
	return {value => 1};
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
