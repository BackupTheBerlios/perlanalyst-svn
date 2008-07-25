package Perl::Analysis::Static::Plugin::Location::DeclarationPackageVariable;

=head1 NAME

Perl::Analysis::Static::Plugin::Location::DeclarationPackageVariable -- Plugin for
  declaration of package variables

=head1 DESCRIPTION

This plugin collects declarations of package variables.

=head1 ADDITIONAL COLUMNS

=over

=item package (STRING)

Name of the package the variable is declared in.

=item variable (STRING)

Name of the variable which is declared.

=back

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::Plugin::Location';

our $VERSION = 1.000;

# FIXME inherit
sub _get_additional_columns {qw(line col package variable)}

# FIXME inherit
sub _get_additional_columns_types {qw(INTEGER INTEGER STRING STRING)}

=head2 analyze ($document)

Find L<PPI::Statement::Package> and L<PPI::Statement::Variable>.
If a variable is 

=cut

sub analyze {
	my ( $self, $document ) = @_;
	my @entries;

	my $statements = $document->find(
		sub {

			# package statement
			$_[1]->isa('PPI::Statement::Package')
				or

				# variable declaration
				$_[1]->isa('PPI::Statement::Variable');
		}
	);

	# return immediately if there are none of these
	return unless $statements;

	for my $statement (@$statements) {
		if ( $statement->isa('PPI::Statement::Package') ) {

			# get significant children
			my @schildren = $statement->schildren();

			# name of the package is the second child
			my $package = $schildren[1];

			print "Package: $package\n";
			next;
		}

		if ( $statement->isa('PPI::Statement::Variable') ) {

			# get significant children
			my @schildren = $statement->schildren();

			# the first child is the keyword, for package
			# variables this has to be 'our'
			next unless $schildren[0] eq 'our';
			
			# variable (or list of variables) is the second child
			my $variables = $schildren[1];

			if ( $variables->isa('PPI::Token::Symbol') ) {
				_parse_token($variables);
			} elsif ( $variables->isa('PPI::Structure::List') ) {
				_parse_list($variables);
			} else {
				use Data::Dumper;
				print "Class not supported: " . Dumper($variables);
				next;
			}    
		}

		# get location
		my $location = $statement->location;
		my $line     = $location->[0];
		my $column   = $location->[2];

		# get significant children
		my @schildren = $statement->schildren();

		# name of the package is the second child
		my $package = $schildren[1];

		# build entry
		my $entry =
			{ line => $line, col => $column, package => $package };

		# add entry
		push @entries, $entry;
	}

	# return undef if nothing was found
	return unless @entries;

	# we have a list of packages, return reference to it
	return \@entries;

}

sub _parse_token {
	my ($token) = @_;

	print "Variable: $token\n";
}

sub _parse_list {
	my ($list) = @_;
	
	# list of symbols, separated by comma operator
	# extract the symbols
	my $symbols=$list->find('PPI::Token::Symbol');
	
	# now only the symbols are left
	print Dumper($symbols);
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

