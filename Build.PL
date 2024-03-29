#! perl

use Module::Build;

my $class = Module::Build->subclass(
	class => 'Module::Build::FilterTests',
	code  => <<'END_HERE',
	
	use File::Glob;
	use File::Spec::Functions;
	
	sub ACTION_disttest
	{
		my $self = shift;
		local $ENV{PERL_RUN_ALL_TESTS} = 1;
		$self->SUPER::ACTION_disttest (@_);
	}
	
	sub find_test_files
	{
		my $self  = shift;
		my $tests = $self->SUPER::find_test_files (@_);
	    
		return $tests unless $ENV{PERL_RUN_ALL_TESTS};
	
		my $test_pattern = catfile (qw(t developer *.t));
		push @$tests, File::Glob::bsd_glob( $test_pattern );
		return $tests;
	}
END_HERE
);

my $build = $class->new(
	license     => 'perl',
	module_name => 'Text::MediawikiFormat',
	requires    =>
	{
		'Scalar::Util'	=> '1.14',
		'URI'		=> '',
		'URI::Escape'	=> '',
		'version'	=> '0.74',
	},
	recommends    =>
	{
		'HTML::Parser'	=> '',
		'HTML::Tagset'	=> '',
	},
	build_requires =>
	{
		'Test::More'   => 0.30,
		'Test::NoWarnings'   => 0,
		'Test::Warn'   => 0,
	},
	create_makefile_pl => 'traditional',
	sign               => '1',
);

$build->create_build_script();
