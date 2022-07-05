package CPT::GalaxyGetOpt;
use CPT::ParameterGroup;
use autodie;
use File::Spec::Functions qw[ catfile catdir ];
use Carp;
no warnings;
use Moose;

has 'appdesc' => ( is => 'rw', isa => 'Str', default => sub { 'No application description provided' } );
has 'appid'   => ( is => 'rw', isa => 'Str', default => sub { "unknown_app_$0" } );
has 'appname' => ( is => 'rw', isa => 'Str', default => sub { "Unnamed application $0"} );
has 'appvers' => ( is => 'rw', isa => 'Str', default => sub { '0.0.1' } );
has 'registered_outputs' => ( is => 'rw', isa => 'HashRef' );
has 'opt' => ( is => 'rw', isa => 'Any');
has filetype_detector => (
    is	    => 'rw',
    isa 	=> 'Any',
);


sub getOptions {
    my ( $self, %passed_opts ) = @_;
    require Getopt::Long::Descriptive;
    # these get pushed through, thankfully. This way we can manually check for --genenrate_galaxy_export and exit slightly earlier.
    my %args = map { $_ => 1 } @ARGV;
    # Sections passed to us
    my @script_args = @{ $passed_opts{'options'} };
    my %defaults    = @{ $passed_opts{'defaults'} };



    # Output Files Stuff
    my @getopt_formatted_outputs;
    my %outputs;
    # This is originally an array of output files. We transform to a hash for
    # easier lookup
    foreach(@{$passed_opts{'outputs'}}){
        # Grab name/desc/opts
        my ($name, $desc, $opts) = @{$_};
        $outputs{$name} = {
            description => $desc,
            options => $opts,
            required => 1,
        };
	my %tmp_opts_fix = %{$opts};
	$tmp_opts_fix{required} = 1;
	$tmp_opts_fix{validate} = 'File/Output';
        push(@getopt_formatted_outputs, [$name, $desc, \%tmp_opts_fix]);

        # Adds the {name}_files_path special parameter
        my %fp_opts = %{$opts};
        $fp_opts{hidden} = 1;
        $fp_opts{value} = "${name}.files_path";
        $fp_opts{default} = "${name}.files_path";
        $fp_opts{required} = 1;
        $fp_opts{_galaxy_specific} = 1;
        $fp_opts{validate} = "String";
        #$fp_opts{_show_in_galaxy} = 0;
        my $desc2 = "Associated HTML files for $name";
        my $name2 = "${name}_files_path";
        my @files_path = ($name2, $desc2, \%fp_opts);
        push(@getopt_formatted_outputs, \@files_path);

        # Adds the {name}_format special parameter
        my %fp_opts3 = %{$opts};
        #$fp_opts3{hidden} = 1;
        $fp_opts3{default} = $fp_opts3{"default_format"};
        $fp_opts3{validate} = "File/OutputFormat";
        $fp_opts{required} = 1;
        #$fp_opts3{_galaxy_specific} = 1;
        #$fp_opts3{_show_in_galaxy} = 0;
        my $desc3 = "Associated Format for $name";
        my $name3 = "${name}_format";
        my @files_path3 = ($name3, $desc3, \%fp_opts3);
        push(@getopt_formatted_outputs, \@files_path3);

        # Adds the {name}_files_path special parameter
        my %fp_opts4 = %{$opts};
        $fp_opts4{hidden} = 1;
        $fp_opts4{value} = "${name}.id";
        $fp_opts4{default} = "${name}.id";
        $fp_opts4{validate} = "String";
        $fp_opts4{_galaxy_specific} = 1;
        #$fp_opts4{_show_in_galaxy} = 0;
        my $desc4 = "Associated ID Number for $name";
        my $name4 = "${name}_id";
        my @files_path4 = ($name4, $desc4, \%fp_opts4);
        push(@getopt_formatted_outputs, \@files_path4);

    }
    $self->registered_outputs(\%outputs);


    # Store the application's name and description
    if($defaults{appdesc}){
        $self->appdesc($defaults{appdesc});
    }
    if($defaults{appid}){
        $self->appid($defaults{appid});
    }
    if($defaults{appname}){
        $self->appname($defaults{appname});
    }
    if($defaults{appvers}){
        $self->appvers($defaults{appvers});
    }

    my $usage_desc;
    if ( $self->appname() && $self->appdesc() ) {
        $usage_desc = sprintf( "%s: %s\n%s [options] <some-arg>", $self->appname(), $self->appdesc(), $0 );
    }

    # Individual parameter parsers
    require CPT::Parameter;
    # Which are stored in a collection of them
    require CPT::ParameterCollection;


    my $parameterCollection = CPT::ParameterCollection->new();

    $parameterCollection->push_params(
        [
            #['Standard Options'],
            #@extra_params,
            #[],
            ['outfile_supporting'   ,  'File or folder to output to, necessary when (class == Report || multiple calls to classyReturnResults || multiple standalone output files)'  ,  { hidden => 1, validate => 'String', default => '__new_file_path__', _galaxy_specific => 1, _show_in_galaxy => 0 }],
            ['galaxy'               ,  'Run with galaxy-specific overrides'                                                                                                          ,  {validate => 'Flag'                      ,  hidden=>1, _galaxy_specific => 1, _show_in_galaxy => 0}],
            ['generate_galaxy_xml'  ,  'Generate a compatible galaxy-xml file. May need editing'                                                                                     ,  {validate => 'Flag'                      ,  hidden=>1, _galaxy_specific => 1, _show_in_galaxy => 0}],
            [],
            ['Script Options'],
        ]
    );

    # If there's a default specified, we should apply that.
    foreach (@script_args) {
        # If it's an array, push as is, because either it's old style/label/empty
        # However, this doesn't allow setting defaults for things that aren't parameters
        # and it won't set defaults for old style
        if ( ref $_ eq 'ARRAY' ) {
            $parameterCollection->push_param($_);
        }elsif( ref $_ eq 'HASH'){
            my $pG = CPT::ParameterGroup->new();
            $pG->set_data($_);
            $parameterCollection->push_group($pG);
        }
    }

    # Our magic output files stuff
    $parameterCollection->push_params(
        [
            [],
            ['Output Files'],
            @getopt_formatted_outputs,
        ]
    );

    # Other standard options like verbosity/version/etc
    $parameterCollection->push_params(
        [
            [],
            ['Other Standard Options'],
            ['verbose|v', 'Be more verbose', {validate => 'Flag', _show_in_galaxy => 0}],
            ['version', 'Print version information', {validate => 'Flag', _show_in_galaxy => 0}],
            ['help', 'Print usage message and exit', {validate => 'Flag', _show_in_galaxy => 0}],
        ],
    );

    # If we want the galaxy_xml, do that before the reduction step is called.
    if ( $args{'--version'} ) {
        print $self->appvers() . "\n";
        exit 1;
    }

    # If we want the galaxy_xml, do that before the reduction step is called.
    if ( $args{'--generate_galaxy_xml'} ) {
        require CPT::Galaxy;
        my $galaxy_xml_generator = CPT::Galaxy->new();
        $galaxy_xml_generator->gen(
            full_options => $parameterCollection,
            appdesc      => $self->appdesc(),
            appid        => $self->appid(),
            appname      => $self->appname(),
            appvers      => $self->appvers(),
            defaults     => $passed_opts{'defaults'},
            outputs      => $passed_opts{'outputs'},
            tests        => $passed_opts{'tests'},
        );
        exit 1;
    }

    if( $args{'--gen_test'} ){
        require CPT::GenerateTests;
        my $tgen = CPT::GenerateTests->new();
        if(defined $passed_opts{'tests'}){
            print $tgen->gen(@{$passed_opts{'tests'}});
        }else{
            print $tgen->gen_empty();
        }
        exit 0;
    }

    # Now that the options_spec is complete, we reduce to something getopt will be happy with
    my @getopt_spec = $parameterCollection->getopt();
    #print STDERR Dumper \@getopt_spec;
    #exit 1;

    # It would be nice if there was a way to ensure that it didn't die here...
    # Execute getopt
    my ( $local_opt, $usage ) = Getopt::Long::Descriptive::describe_options( $usage_desc, @getopt_spec );
    $self->opt($local_opt);

    # Now that we've gotten the user's options, we need to copy their values back to our ParameterCollection
    $parameterCollection->populate_from_getopt($self->opt());

    # If they want help, print + exit
    if ( $self->opt && $self->opt->help ) {
        print $usage;
        exit 1;
    }
    # Validate their choices
    if ( $parameterCollection->validate($self->opt) ) {
        return $self->opt;
        # Easy access for the script, don't want them to have to deal with PC (just yet)
    }
    else {
        # Some params failed to validate, so we die.
        croak "Validation errors were found so cannot continue";
    }
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::GalaxyGetOpt

=head1 VERSION

version 1.99.4

=head2 getOptions

	my $ggo = CPT::GalaxyGetOpt->new();
	my $options = $ggo->getOptions(
		'options' => [
			[ 'file', 'Input file', { validate => 'File/Input' } ],
			[
				"option" => "Select an option!",
				{
					validate => 'Option',
					options  => \%options,
					multiple => 1,
				}
			],
			[
				"float" => "I'm a float",
				{ validate => 'Float' }
			],
			[
				"int" => "I'm an int",
				{ validate => 'Int', default => [42, 34], required => 1, multiple => 1 }
			],
			[],
			['New section'],
			[
				"string" => "I'm a simple string",
				{ validate => 'String' }
			],
			[
				'flag' => 'This is a flag',
				{ validate => 'Flag' }
			],
		],
		'outputs' => [
			[
				'my_output_data',
				'Output TXT File',
				{
					validate       => 'File/Output',
					required       => 1,
					default        => 'out',
					data_format    => 'text/plain',
					default_format => 'TXT',
				}
			],
		],
		'defaults' => [
			'appid'   => 'TemplateScript',
			'appname' => 'Template',
			'appdesc' => 'A basic template for a new CPT application',
			'appvers' => '1.94',
		],
		'tests' => [
			{
				test_name    => "Default",
				params => {
				},
				outputs => {
					'my_output_data' => ["out.txt", 'test-data/outputs/template.default.txt' ],
				},
			},
			{
				test_name    => "Option A specified",
				params => {
					'int', '10000',
				},
				outputs => {
					'my_output_data' => ["out.txt", 'test-data/outputs/template.A.txt' ],
				},
			},
		],
	);

	my @data;
	foreach(qw(file int string option float flag)){
		# Create a 2D array of all of our optoins
		push(@data, [ $_, $options->{$_}]);
	}

	my %table = (
		'Sheet1' => {
			header => [qw(Key Value)],
			data => \@data,
		}
	);

	# And store it to file!
	use CPT::OutputFiles;
	my $crr_output = CPT::OutputFiles->new(
		name => 'my_output_data',
		GGO => $ggo,
	);
	$crr_output->CRR(data => \%table);

Gets command line options, and prints docs. Very convenient, removes the burden of writing any Getopt code from you.

=head3 Default Options Provided

=over 4

=item *

help, man - cause an early exit and printing of the POD for your script.

=item *

verbose - flag to make the script verbose. Will print everything that is sent to returnResults. Individual scripts should take advantage of this option

=back

=head3 Advanced Options Provided

=over 4

=item C<--generate_galaxy_xml>

Generates valid XML for the tool for use in Galaxy

=item C<--gen_test>

Generates code to test the script using specified test data

=back

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
