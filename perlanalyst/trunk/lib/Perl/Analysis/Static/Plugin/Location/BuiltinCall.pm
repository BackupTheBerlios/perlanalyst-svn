package Perl::Analysis::Static::Plugin::Location::BuiltinCall;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::BuiltinCall -- Plugin for
  calls of builtins

=head1 DESCRIPTION

This plugin collects calls of builtin functions.

=head1 ADDITIONAL COLUMN

=over

=item builtin (STRING)

Name of the builtin called.

=back

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

use Perl::Critic::Utils qw(is_function_call is_perl_builtin);

our $VERSION = 1.000;

sub _get_additional_columns {qw(line col builtin)}

sub _get_additional_columns_types {qw(INTEGER INTEGER STRING)}

#sub _get_primary_columns {qw(hex_id line col)}

=head2 analyze ($document)

=cut

sub analyze {
	my ( $self, $document ) = @_;
	my @entries;

	# function calls are words
	my $words = $document->find('PPI::Token::Word');

	# return immediately if there are no words in the file
	return unless @$words;

	for my $word (@$words) {

		# skip if word is not builtin
		next unless is_perl_builtin($word);

		# get location
		my $location = $word->location;
		my $line     = $location->[0];
		my $column   = $location->[2];

		# stringify it, otherwise we get the whole object
		my $builtin = "$word";

		# build entry
		my $entry =
			{ line => $line, col => $column, builtin => $builtin };

		# add entry
		push @entries, $entry;
	}

	# return undef if nothing was found
	return unless @entries;

	# we have a list of builtin calls, return reference to it
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
