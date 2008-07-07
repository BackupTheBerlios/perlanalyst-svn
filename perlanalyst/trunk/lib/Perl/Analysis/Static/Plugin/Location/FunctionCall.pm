package Perl::Analysis::Static::Plugin::Location::FunctionCall;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::FunctionCall -- Plugin for
  function calls

=head1 DESCRIPTION

This plugin collects function calls.

=head1 ADDITIONAL COLUMN

=over

=item function (STRING)

Name of the function called.

=back

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

use Perl::Critic::Utils qw(is_function_call is_perl_builtin);

our $VERSION = 1.000;

sub _get_additional_columns {qw(line col function)}

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

		# skip if function is builtin
		next if is_perl_builtin($word);

		# skip unless we have a function call
		next unless is_function_call($word);

		# get location
		my $location = $word->location;
		my $line     = $location->[0];
		my $column   = $location->[2];

		# stringify it, otherwise we get the whole object
		my $function = "$word";

		# build entry
		my $entry =
			{ line => $line, col => $column, function => $function };

		# add entry
		push @entries, $entry;
	}

	# return undef if nothing was found
	return unless @entries;

	# we have a list of function calls, return reference to it
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

