package Perl::Analysis::Static::Plugin::Location::Counter;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::Counter -- Example plugin for an analysis
	that's unique per location 

=head1 DESCRIPTION

Example plugins that's FIXME...

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

our $VERSION=1.000;

=head2 analyze ($document)

Main method for the analysis. The only argument is an instance
of the class L<PPI::Document> which represents the document to
analyze. This method may analyze the document in any way it wants
to.

Returns: FIXME

=cut

my $counter=0;

sub analyze {
	return {line => $counter++, col => 0};
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
