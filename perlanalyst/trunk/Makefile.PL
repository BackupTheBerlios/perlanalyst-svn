use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Perl::Analysis::Static',
	VERSION   => '0.001',
	ABSTRACT => 'Static analysis of Perl documents',
	AUTHOR    => 'Gregor Goldbach <ggoldbach@cpan.org>',
	PREREQ_PM => {
		Class::DBI        => 0,
		PPI               => 0,
		File::Find::Rule  => 0,
		DBD::SQLite       => 0,
		Perl::Critic      => 0,
		Module::Pluggable => 0
	},
	LICENSE      => 'perl',
        EXE_FILES    => ['scripts/perlanalyst'],
	PREREQ_FATAL => 1
);
