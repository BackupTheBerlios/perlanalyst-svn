package Perl::Analysis::Static::DBI;

use strict;
use warnings;

=head1 NAME

  Perl::Analysis::Static::DBI -- Table per instance

=head1 DESCRIPTION

Instances that want to have a table just need to inherit from this. The
only method in this class connects to the database.

=cut

use Perl::Analysis::Static::Database qw(connect_to_database);

use base qw(Class::DBI);

our $VERSION=1.000;

=head1 METHODS

=head2 db_Main

Redirect to connect_to_database().

=cut

sub db_Main {
	return connect_to_database();
}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT orgE<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static::Database>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
