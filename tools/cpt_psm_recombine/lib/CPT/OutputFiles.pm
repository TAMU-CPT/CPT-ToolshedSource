package CPT::OutputFiles;
use Carp;
use Moose;
use strict;
use warnings;
use autodie;
use File::Spec;


# ABSTRACT: Handles script outputs in a sane way, providing facilities to format data and name files for regular use, or in galaxy.


# A list of acceptable ouput formats. Some/many of these may be missing implementations.
# For instance, the pandoc output format is completely unimplemented
# These will NEED to be re-worked.
has 'acceptable_formats' => (
	is      => 'ro',
	isa     => 'HashRef',
	default => sub {
		{
			'text/tabular'      => [qw(TSV TSV_U CSV CSV_U XLS ODS Dumper JSON YAML XLSX)],
			'genomic/annotated' => [qw(ABI Ace AGAVE ALF AsciiTree BSML BSML_SAX ChadoXML Chaos ChaosXML CTF EMBL EntrezGene Excel Exp Fasta Fastq GAME GCG Genbank Interpro KEGG LargeFasta LaserGene LocusLink PHD PIR PLN Qual Raw SCF SeqXML Strider Swiss Tab TIGR TIGRXML TinySeq ZTR)],
			'genomic/raw'       => [qw(Fasta)],
			'genomic/interval'  => [qw(GFF3)],
			'text/html'         => [qw(HTML)], # Theoretically this will be consumed by text/report
			'text/report'       => [qw(Pandoc)],
			'text/plain'        => [qw(TXT CONF)],
			'image/svg'         => [qw(SVG)],
			'image/png'         => [qw(PNG)],
			'archive'           => [qw(tar.gz zip tar)],
			'Dummy'             => [qw(Dummy)],
		}
	}
);

has 'format_mapping' => (
	is      => 'ro',
	isa     => 'HashRef',
	default => sub {
		{
			'TSV'        => 'tabular',
			'CSV'        => 'tabular',
			'TSV_U'      => 'tabular',
			'CSV_U'      => 'tabular',
			'XLS'        => 'data',
			'ODS'        => 'data',
			'Dumper'     => 'txt',
			'JSON'       => 'txt',
			'YAML'       => 'txt',
			'XLSX'       => 'data',
			'Fasta'      => 'fasta',
			'GFF3'       => 'interval',
			'HTML'       => 'html',
			'Pandoc'     => 'txt',
			'TXT'        => 'txt',
			'CONF'       => 'txt',
			'SVG'        => 'xml',
			'PNG'        => 'png',
			'Dummy'      => 'data',
			'tar.gz'     => 'tar.gz',
			'zip'        => 'zip',
			'tar'        => 'tar',
			#Genomic formats
			'ABI'        => 'data',
			'Ace'        => 'txt',
			'AGAVE'      => 'xml',
			'ALF'        => '',
			'AsciiTree'  => 'txt',
			'BSML'       => 'xml',
			'BSML_SAX'   => 'xml',
			'ChadoXML'   => 'xml',
			'Chaos'      => 'xml',
			'ChaosXML'   => 'xml',
			'CTF'        => 'data',
			'EMBL'       => 'txt',
			'EntrezGene' => 'txt',
			'Excel'      => 'data',
			'Exp'        => 'txt',
			'Fastq'      => 'fastq',
			'GAME'       => 'xml',
			'GCG'        => 'txt',
			'Genbank'    => 'txt',
			'Interpro'   => 'xml',
			'KEGG'       => 'txt',
			'LargeFasta' => 'txt',
			'LaserGene'  => 'data',
			'LocusLink'  => 'data',
			'PHD'        => 'data',
			'PIR'        => 'data',
			'PLN'        => 'data',
			'Qual'       => 'data',
			'Raw'        => 'txt',
			'SCF'        => 'data',
			'SeqXML'     => 'xml',
			'Strider'    => 'data',
			'Swiss'      => 'txt',
			'Tab'        => 'tabular',
			'TIGR'       => 'xml',
			'TIGRXML'    => 'xml',
			'TinySeq'    => 'xml',
			'ZTR'        => 'data',
		}
	}
);

sub valid_formats {
	my ($self, $format) = @_;
	return ${$self->acceptable_formats()}{$format};
}

sub get_format_mapping{
	my ($self, $format) = @_;
	return ${$self->format_mapping()}{$format};
}


# User supplied options
has 'name' => ( is => 'ro', isa => 'Str' );
has 'GGO' => ( is => 'ro', isa => 'Any' );
has 'galaxy' => (is => 'rw', isa => 'Bool');

# These are extracted on init from from CPT
has 'output_id'    => (is => 'rw', isa => 'Str');
has 'output_label' => (is => 'rw', isa => 'Str');
has 'output_opts'  => (is => 'rw', isa => 'HashRef');
# From galaxy
has 'new_file_path' => (is => 'rw', isa => 'Str');
has 'files_path' => (is => 'rw', isa => 'Str');
has 'files_id' => (is => 'rw', isa => 'Str');
# ???
has 'parent_filename' => (is => 'rw', isa => 'Str');
has 'parent_internal_format' => (is => 'rw', isa => 'Str');
has 'parent_default_output_format' => (is => 'rw', isa => 'Str');

has 'init_called' => (is => 'rw', isa =>'Bool');

sub initFromArgs {
	my ($self, %args) = @_;
	
	# We will only ever care about one (as there is one of these objects
	# per registered output)
	my %registered_outputs = %{$self->GGO()->registered_outputs()};
	# If the output name specified in "name" was not known to registered_outputs
	if(!defined($self->name())){
		croak("You must supply a name to the instantiation of CRR");
	}
	#if(!defined($registered_outputs{$args{name}})){
		#croak("The script author tried to call GGO's classyReturnResults method with an output file not mentioned in the outputs section.");
	#}

	# Carrying on
	# We grab the pre-specified data regarding that output
	my %reg_out_params = %{$registered_outputs{$self->name()}};
	# Store these for future calls of sub/var
	$self->output_id($self->name());
	$self->output_label($reg_out_params{description});
	$self->output_opts($reg_out_params{options});


	$self->parent_internal_format($reg_out_params{options}{data_format});
	$self->parent_default_output_format($reg_out_params{options}{default_format});
	$self->parent_filename($reg_out_params{options}{default});

	# Special variables
	# --genemark "${genemark}" --genemark_format "${genemark_format}"
	# --genemark_files_path "${genemark_files_path}"
	# --genemark_id "${genemark_id}"

	# If they've specified a filename on the command line, that should
	# override the default value
	if(defined $self->GGO->opt->{$self->name()}){
		$self->parent_filename($self->GGO->opt->{$self->name()});
	}
	# If they've specified a {str}_format option on the command line, that
	# should override the default value
	if(defined $self->GGO->opt->{$self->name() . '_format'}){
		$self->parent_default_output_format($self->GGO->opt->{$self->name() . '_format'});
	}

	# Grab supporting files path (added as new history items)
	$self->new_file_path($self->GGO->opt->{outfile_supporting});
	# Copy galaxy specific variables
	if(defined $self->GGO->opt->{$self->name() . '_files_path'}){
		$self->files_path($self->GGO->opt->{$self->name() . '_files_path'});
	}
	if(defined $self->GGO->opt->{$self->name() . '_id'}){
		$self->files_id($self->GGO->opt->{$self->name() . '_id'});
	}

	# If --galaxy has been specified, we need to be aware of this
	if ( $self->GGO->opt->{galaxy} ) {
		$self->galaxy(1);
	}else{
		$self->galaxy(0);
	}
	$self->init_called(1);
}



has 'times_called' => ( is => 'rw', isa => 'Num', default => sub {0} );
has 'naming_strategy' => ( is => 'rw', isa => 'Str', default =>  "norm" ); #Other options are "var" and "sub"


sub _genCRR {
	my ($self, %args) = @_;
	if(!$self->init_called()){
		$self->initFromArgs(%args);
	}

	# If the user supplied a custom extension, pull that (useful in
	# dummy/data output type)
	if(defined $args{extension}){
		$self->extension($args{extension});
	}

	# This is a mandatory parameter
	if(!defined $args{filename}){
		$self->given_filename($self->parent_filename());
	}else{
		$self->given_filename($args{filename});
	}

	# Allow overriding default format parameters
	my $writer = $self->writer_for_format(
		defined $args{data_format} ? $args{data_format} : $self->parent_internal_format(),
		defined $args{format_as} ? $args{format_as} : $self->parent_default_output_format(),
	);

	# Ugh
	$writer->OutputFilesClass($self);
	if($args{'data'}){
		$writer->data( $args{'data'} );
	}
	$writer->process_data();
	$writer->write();
	my @returned_filenames = @{$writer->used_filenames()};
	print STDERR join("\n",map{"FN: $_"} @returned_filenames)."\n";
	$self->bump_times_called();
	return @returned_filenames;
}


sub CRR {
	my ( $self, %args ) = @_;
	return $self->_genCRR(%args);
}


sub subCRR {
	my ( $self, %args ) = @_;
	# Change naming behaviour
	$self->naming_strategy('sub');
	return $self->_genCRR(%args);
}


sub varCRR {
	my ( $self, %args ) = @_;
	# Change naming behaviour
	$self->naming_strategy('var');
	return $self->_genCRR(%args);
}


sub bump_times_called{
	my ($self) = @_;
	$self->times_called($self->times_called() + 1 );
	return $self->times_called();
}


sub writer_for_format{
	my($self, $format, $requested) = @_;

	# For the specified data_format, grab the acceptable handlers for that format
	my %acceptable = %{$self->acceptable_formats()};
	my %acceptable_handlers = map { $_ => 1 } @{ $acceptable{ $format } };
	
	if (!$acceptable_handlers{$requested} ) {
	carp(sprintf( "Unacceptable output format choice [%s] for internal"
			."data type for type %s. Acceptable formats are [%s]."
			."Alternatively, unacceptable output file.", $requested, $format,
			join( ', ', keys(%acceptable_handlers) ) ));
	}

	if ( $requested eq 'Dumper' ) {
		require CPT::Writer::Dumper;
		return CPT::Writer::Dumper->new();
	}
	elsif ( $requested eq 'TSV' ) {
		require CPT::Writer::TSV;
		return CPT::Writer::TSV->new();
	}
	elsif ( $requested eq 'CSV' ) {
		require CPT::Writer::CSV;
		return CPT::Writer::CSV->new();
	}
	elsif ( $requested eq 'TSV_U' ) {
		require CPT::Writer::TSV_U;
		return CPT::Writer::TSV_U->new();
	}
	elsif ( $requested eq 'CSV_U' ) {
		require CPT::Writer::CSV_U;
		return CPT::Writer::CSV_U->new();
	}
	elsif ( $requested eq 'YAML' ) {
		require CPT::Writer::YAML;
		return CPT::Writer::YAML->new();
	}
	elsif ( $requested eq 'JSON' ) {
		require CPT::Writer::JSON;
		return CPT::Writer::JSON->new();
	}
	elsif ( $requested eq 'Pandoc' ) {
		require CPT::Writer::Pandoc;
		return CPT::Writer::Pandoc->new();
	}
	elsif ( $requested eq 'XLS' ) {
		require CPT::Writer::Spreadsheet::XLS;
		return CPT::Writer::Spreadsheet::XLS->new();
	}
	elsif ( $requested eq 'XLSX' ) {
		require CPT::Writer::Spreadsheet::XLSX;
		return CPT::Writer::Spreadsheet::XLSX->new();
	}
	elsif ( $requested eq 'TXT' || $requested eq 'CONF' ) {
		require CPT::Writer::TXT;
		return CPT::Writer::TXT->new();
	}
	elsif ( $acceptable_handlers{$requested} && $format eq 'genomic/annotated'){
		require CPT::Writer::Genomic;
		return CPT::Writer::Genomic->new(format => $requested);
	}
	elsif ( $requested eq 'Fasta' ) {
		require CPT::Writer::Fasta;
		return CPT::Writer::Fasta->new();
	}
	elsif ( $requested eq 'GFF3' ) {
		require CPT::Writer::GFF3;
		return CPT::Writer::GFF3->new();
	}
	elsif ( $requested eq 'HTML' ) {
		require CPT::Writer::HTML;
		return CPT::Writer::HTML->new();
	}
	elsif ( $requested eq 'SVG' ) {
		require CPT::Writer::SVG;
		return CPT::Writer::SVG->new();
	}
	elsif ( $requested eq 'PNG' ) {
		require CPT::Writer::Dummy;
		return CPT::Writer::Dummy->new();
	}
	elsif ( $requested eq 'Dummy' ) {
		require CPT::Writer::Dummy;
		return CPT::Writer::Dummy->new();
	}
	elsif ( $requested eq 'tar.gz') {
		require CPT::Writer::Archive;
		return CPT::Writer::Archive->new( format => 'tar.gz' );
	}
	elsif ( $requested eq 'zip') {
		require CPT::Writer::Archive;
		return CPT::Writer::Archive->new( format => 'zip' );
	}
	elsif ( $requested eq 'tar') {
		require CPT::Writer::Archive;
		return CPT::Writer::Archive->new( format => 'tar' );
	}
	else {
		carp(sprintf("Data Format not yet supported [%s, %s]", $format, $requested));
	}
}

# File extension
has 'extension' => ( is => 'rw', isa => 'Str');
# What the user said this file was called.
has 'given_filename' => (is => 'rw', isa => 'Str');




sub generate_galaxy_variable{
	my ($self) = @_;
	unless( -d $self->new_file_path()){
		mkdir($self->new_file_path());
	}
	my $filename =File::Spec->catfile(
		$self->new_file_path(),
		sprintf( "primary_%s_%s_visible_%s", $self->files_id(), $self->given_filename(), $self->extension())
	);
	return $filename;
}


sub generate_nongalaxy_variable{
	my ($self) = @_;
	my $filename =File::Spec->catfile(
		sprintf( "%s.%s", $self->given_filename(), $self->extension())
	);
	return $filename;
}


sub generate_galaxy_subfile {
	my ($self) = @_;
	unless( -d $self->files_path()){
		mkdir($self->files_path());
	}
	my $filename =File::Spec->catfile(
		$self->files_path,
		sprintf( "%s.%s", $self->given_filename(), $self->extension())
	);
	return $filename;
}


sub generate_nongalaxy_subfile {
	my ($self) = @_;
	# they're pretty much equivalent for now
	return $self->generate_galaxy_subfile();
}


sub get_next_file{
	my ($self) = @_;
	my $filename;
	if ( $self->galaxy() ) {
		# In which case we want to return the primary output file.
		if ( $self->times_called() == 0 ) {
			$filename = $self->parent_filename();
		}
		else {
			if ( $self->naming_strategy eq 'sub' ) {
				$filename = $self->generate_galaxy_subfile();
			}
			elsif($self->naming_strategy eq 'var') {
				$filename = $self->generate_galaxy_variable();
			}else{
				confess("Unknown startegy for multiple output files: " . $self->naming_strategy());
			}
		}
	}
	else	# do NOT use galaxy overrides. Paths should be more...sane
	{
		# First time we request, should $filename = the primary value, which
		# should be the file they specify.
		if ( $self->times_called() == 0 ) {
			$filename = $self->given_filename() . '.' . $self->extension();
		}
		else {
			if ( $self->naming_strategy eq 'sub' ) {
				$filename = $self->generate_nongalaxy_subfile();
			}
			elsif($self->naming_strategy eq 'var') {
				$filename = $self->generate_nongalaxy_variable();
			}else{
				confess("Unknown startegy for multiple output files: " . $self->naming_strategy());
			}
		}
	}
	return $filename;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::OutputFiles - Handles script outputs in a sane way, providing facilities to format data and name files for regular use, or in galaxy.

=head1 VERSION

version 1.99.4

=head1 METHODS

=head2 initFromArgs

    $o->initFromArgs(name => 'GGO_known_output_name', GGO => $GGO);

Internal method to intialise data structures from the output id provide in C<name> and the data accessible via the C<GGO> object. You B<must> have already called C<< $GGO->getOptions >>

=head2 classyReturnResults

	# in $GGO->getOptions(
		outputs => [
			['html_page', 'HTML output page',
				{
					validate => 'File/Output',
					default => 'aa', # will produce aa.html
					data_format => 'text/html',
					default_format => 'HTML'
				}
			]
			['genbank_download', 'Variable number of GBK files',
				{
					validate => 'File/Output',
					default => 'result', # will produce result.gbk
					data_format => 'genomic/annotated',
					default_format => 'Genbank'
				}
			]
		]
	# )

	# Then in your script
	$csv_output = CPT::OutputFiles->new(
		name => 'html_page',
		opt => $options,
	);
	$csv_output->CRR(
		data => $data
	);
	# Subfile
	my $loc = $csv_output->subCRR(
		filename => 'cool_picture',
		data_format=>'data',
		extension=>"png"
	);
	move($png_file,$loc);

	# You give subfiles a name in case you need to refer to them at any
	# point in the parent file.
	$csv_output->subCRR(
		filename => 'output',
		data => $svg_object,
		data_format => 'image/svg',
		format_as => 'SVG'
	);


	$gbk_output = CPT::OutputFiles->new(
		name => 'genbank_download',
		opt => $options,
	);
	while(my $individual_genbank = $large_seqio->next){
		$gbk_output->varCRR(
			filename => $individual_genbank->seqid(),
			data => $individual_genbank,
		);
	}

=head2 _genCRR

    _genCRR(extension => 'png', data => $data_ref, data_format => 'Dummy',
            format_as => 'Dummy', filename => "my-image");

This is an internal method and should not be called directly. It's the end call of all C<CRR>, C<subCRR>, and C<varCRR>. Those methods should be used instead.

This method

=over 4

=item Stores some parameters

Specifically C<extension>, C<filename>, C<data_format>, C<format_as>

=item Creates a CPT::Writer

=item Calls the writer's C<write> method

=item returns an array (not arrayref) of filenames 

These were the filenames that were produced in the writing process. This may be useful for data like CSV data where the output writer may produce N differently named files for each sheet of data.

=back

=head2 CRR

    $o->CRR(data => $ref);

Writes data to an appropriately named file. (This is usually the "default" parameter supplied in the definition of this output). You should call this method first.

=head2 subCRR

    $o->subCRR(data => $ref, filename => 'subreport', extension => 'html', data_format => 'text/html', format_as => 'HTML');

Writes data to an appropriately named sub file. A subfile is a file that will appear in a folder in the current directory. Subfiles are useful when you want to reference other output files in a primary HTML output or similar. C<subCRR> gives you a method to produce files and have them automatically placed in a sensible location, from which you can reference the files.

Files are placed in C<< $self->files_path >>. We C<mkdir> this for you, ignoring any errors. If you're paranoid you might want to re-run the mkdir/test for permissions/etc.

You must provide

=over 4

=item filename

name for the output file. You must generate this or it will be named identically to the parent. (And if you call it twice they will clobber each other silently and without mercy)

=item extension

E.g., 'png'

=item data_format

Internal data type. One of the standard C<text/html>, C<genomic/raw>, C<genomic/annotated>, etc.

=item format_as

You're welcome to provide a way to access the format parameter of subfiles to your users, however this is not done for you as there is no way for this module to know ahead of time how many subfiles you will produce.

=back

You may call this method after the first call to CRR or instead of calls to CRR

=head2 varCRR

    $o->varCRR(data => $ref, filename => 'subreport', extension => 'html', data_format => 'text/html', format_as => 'HTML');

Writes data to an appropriately named var file. A var file or variable file is much like a subfile, except that in galaxy they will show up as individual history items. Additionally, the default behaviour from the command line is to place all generated files in the current working directory, rather than in a special folder.

You must provide

=over 4

=item filename

name for the output file. You must generate this or it will be named identically to the parent. (And if you call it twice they will clobber each other silently and without mercy)

=item extension

E.g., 'png'

=item data_format

Internal data type. One of the standard C<text/html>, C<genomic/raw>, C<genomic/annotated>, etc.

=item format_as

You're welcome to provide a way to access the format parameter of subfiles to your users, however this is not done for you as there is no way for this module to know ahead of time how many subfiles you will produce.

=back

You may call this method after the first call to CRR or instead of calls to CRR

=head2 bump_times_called

    $o->bump_times_called();

Bumps the internal number representing the number of times you've tried to output files for a given output object. This data is used in construction of filenames

=head2 writer_for_format

    $o->writer_for_format('text/tabular', 'TSV_U');

Get the appropriate writer class and instantiate it for a given C<data_format> and C<format_as>.

=head2 generate_galaxy_variable

    $o->generate_galaxy_variable();

If we need the files to show up as separate History items in galaxy, filenames have to be constructed like this:

=over 4

=item F<$filepath/primary_546_output2_visible_bed>

=item F<$filepath/primary_546_output3_visible_pdf>

=back

where filenames consist of 'primary', an ID number (provided in C<outputname_id> on the command lien), a filename, 'visible', and an extension, all joined with C<_>. Additionally C<$filepath> is generally CWD (I think...)

=head2 generate_nongalaxy_variable

    $o->generate_nongalaxy_variable();

=over 4

=item F<$given_filename.$extension>

=back

Parameters are taken from the object variables of the same names.

=head2 generate_galaxy_subfile

    $o->generate_galaxy_subfile();

=over 4

=item F<$files_path/$given_filename.$extension>

=back

The paths for images and other files will end up looking something like
F</home/galaxy/galaxy_dist/database/files/000/dataset_56/img1.jpg> with the galaxy provided C<files_path> prepended to the filename.

=head2 generate_nongalaxy_subfile

    $o->generate_nongalaxy_subfile();

See L</generate_galaxy_subfile>. Know that the default for C<< $self->files_path >> is C<"outputname.files_path">. It's only "special" when run from inside galaxy.

=head2 get_next_file

    $o->get_next_file();

If it's the first time this method has been called, it constructs a default filename. If the C<galaxy> variable is true, then it's just whatever value was passed. Otherwise it's just C<given_filename> and C<extension> put together. C<given_filename> is taken from C<parent_filename>.

If it's not the first time it was called, this module expects you to be using L</varCRR> or L</subCRR> to call (which has set C<naming_strategy>). Those will generate appropriate filenames with calls to one of

=over 4

=item L</generate_galaxy_subfile>

=item L</generate_galaxy_variable>

=item L</generate_nongalaxy_subfile>

=item L</generate_nongalaxy_variable>

=back

based on appropriate variables.

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
