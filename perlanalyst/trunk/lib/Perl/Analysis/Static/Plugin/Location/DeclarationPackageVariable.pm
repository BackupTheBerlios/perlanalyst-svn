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
sub _get_additional_columns { qw(line col package variable) }

# FIXME inherit
sub _get_additional_columns_types { qw(INTEGER INTEGER STRING STRING) }

=head2 analyze ($document)

Find L<PPI::Statement::Package> and L<PPI::Statement::Variable>.
If a variable is 

=cut

sub analyze {
	my ( $self, $document ) = @_;
	my @entries;

	my $statements = $document->find( \&_filter );

	# return immediately if there are none of these
	return unless $statements;

	my $items = _build_item_list($statements);

	# return undef if nothing was found
	return unless $items;

	for my $item (@$items) {
		push @entries, _build_entry($item);
	}

	return \@entries;
}

sub _filter {

	# package statement
	$_[1]->isa('PPI::Statement::Package')
	  or

	  # variable declaration
	  $_[1]->isa('PPI::Statement::Variable');
}

sub _build_item_list {
	my ($statements) = @_;

	# The package name is changed with the 'package'
	# keyword. Variables before the first occurrence of
	# this keyword are declared in the current package.
	# Whatever that is...
	my $package = '__CURRENT_PACKAGE__';

	my $variable;

	my @entries;

	for my $statement (@$statements) {
		if ( $statement->isa('PPI::Statement::Package') ) {

			# get significant children
			my @schildren = $statement->schildren();

			# name of the package is the second child
			$package = $schildren[1];

			$package = "$package";
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
				$variable = $variables;
				print "** ${package}::$variable\n";
				push @entries,
				  {
					package  => $package,
					variable => $variable
				  };
			}
			elsif ( $variables->isa('PPI::Structure::List') ) {

				# list of symbols, separated by comma operator
				# extract the symbols
				my $symbols = $variables->find('PPI::Token::Symbol');

				# now only the symbols are left
				for my $symbol (@$symbols) {
					$variable = $symbol;
					print "** ${package}::$symbol\n";

					push @entries,
					  {
						package  => $package,
						variable => $variable
					  };

				}
			}
			else {
				use Data::Dumper;
				print "Class not supported: " . Dumper($variables);
				next;
			}

		}

		# now there are package names and variable PPI::Elements
		# in @entries

		# now we have to turn those into the hashes that are returned
		# from analyze
	}
	return \@entries;
}    

# build entry from the internal entry
sub _build_entry {
	my ($entry) = @_;

	my $variable = $entry->{variable};
	my $package  = $entry->{package};

	# get location
	my $location = $variable->location;
	my $line     = $location->[0];
	my $column   = $location->[2];

	return {
		line      => $line,
		col       => $column,
		package   => $package,
		variable => "$variable"
	};
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

