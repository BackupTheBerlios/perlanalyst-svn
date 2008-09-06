package Perl::Analysis::Static::ColumnType;

=head1 NAME

Perl::Analysis::Static::ColumnType

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter);

our $VERSION = 1.000;
our @EXPORT_OK=qw(set_column_type get_column_type);

# core columns
set_column_type('col' ,'INTEGER');
set_column_type('file' ,'TEXT NOT NULL');
set_column_type('hex_id' ,'TEXT NOT NULL');
set_column_type('line' ,'INTEGER');
set_column_type('name' ,'TEXT NOT NULL');
set_column_type('version' ,'INTEGER');

# plugins
set_column_type('function' ,'TEXT NOT NULL');
set_column_type('package' ,'TEXT NOT NULL');
set_column_type('variable' ,'TEXT NOT NULL');

{
	my $type_for;

=head2 set_column_type ($name, $type)

=cut

	sub set_column_type {
		my ($name, $type)=@_;
		
		$type_for->{$name}=$type;
		
		return 1;
	}

=head2 get_column_type ($name)

=cut
	
	sub get_column_type {
		my ($name)=@_;
		
		return unless exists $type_for->{$name};
		
		return $type_for->{$name};
	}
}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

