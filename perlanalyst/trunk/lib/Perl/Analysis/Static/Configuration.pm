package Perl::Analysis::Static::Configuration;

=head1 NAME

Perl::Analysis::Static::Configuration - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base qw(Exporter);

use Config::General qw(ParseConfig);

our $VERSION   = 1.000;
our @EXPORT_OK = qw(read_configuration get_config);

our $configuration;

=head2 read_configuration ($filename)

=cut

sub read_configuration {
	my ($filename) = @_;

	unless ( -e $filename ) {
		die "Unable to load configuration from file '$filename'";
	}

	my $conf = new Config::General(
		-ConfigFile      => $filename,
		-InterPolateVars => 1
	);

	my %config = $conf->getall();
	$configuration = \%config;

	return 1;
}

=head2 get_config ($entry)

=cut

sub get_config {
	my ($entry) = @_;

	return $configuration->{$entry};
}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static>, L<Config::General>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
