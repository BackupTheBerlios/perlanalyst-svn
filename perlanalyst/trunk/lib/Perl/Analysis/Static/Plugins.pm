package Perl::Analysis::Static::Plugins;

=head1 NAME

Perl::Analysis::Static::Plugins --

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter);

use Perl::Analysis::Static::Log qw(message);

use Module::Pluggable search_path => ['Perl::Analysis::Static::Plugin'];

our $VERSION = 1.000;
our @EXPORT_OK=qw(get_plugins load_plugins
get_plugins_that_can_analyze);


sub get_plugins { return __PACKAGE__->plugins() };

sub get_plugins_that_can_analyze {
	my @plugins=get_plugins;

	return grep ($_->can_analyze(), @plugins);
};

sub load_plugins {

	# load plugin modules
	for my $plugin ( get_plugins() ) {
		message("Loading plugin '$plugin'");
		eval "require $plugin; $plugin->import()";

		# die on error
		die $@ if $@;
	}
}


=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

