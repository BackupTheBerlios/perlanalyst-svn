#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use PPI;
use PPI::Document;

my $module;

BEGIN {
	$module =
		'Perl::Analysis::Static::Plugin::Location::DeclarationPackageVariable';

	use_ok($module) or BAIL_OUT;
}

my $file = 't/data/DeclarationPackageVariable.pl';

# load document from file
my $document = PPI::Document->new($file);
$module->analyze($document);    
