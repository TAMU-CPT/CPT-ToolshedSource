package CPT::Parameter::File::Input;
use Moose;
with 'CPT::Parameter';

has 'format'      => ( is => 'rw', isa => 'Str' );
has 'file_format' => ( is => 'rw', isa => 'ArrayRef' );

# Format is something like "fastq", "bam", etc.
# This means when you write the parameter string it'll be
# ['file|f=s', 'Input Bam File', { required => 1, format=> 'file/input/bam'} ]
# Which will specify that you require a BAM file.


sub galaxy_input {
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('data');
	if( defined $self->file_format() ){
		$params{format} = join( ',', @{$self->file_format()} );
	}
	$xml_writer->startTag(
		'param',
		%params
	);
	$xml_writer->endTag('param');
	$self->handle_possible_galaxy_input_repeat_end($xml_writer);
}


sub galaxy_output {
	my ($self, $xml_writer) = @_;
	return $xml_writer;
}


sub validate_individual {
	my ($self, $val) = @_;

	# Maybe do format validation here? Maybe?
	if ( -e $val ) {
		return 1;
	}else{
		push(@{$self->errors()}, sprintf( "File [%s] supplied to option %s does not exist", $val,$self->name()));
		return 0;
	}
}


sub getopt_format {
	return '=s';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::File::Input

=head1 VERSION

version 1.99.4

=head2 galaxy_input

	$file_param->galaxy_input($xml_writer); # where $file_param is a CPT::Parameter::*

Utilises the $xml_writer to add a <data> block in the <output> section

=head2 galaxy_output

	$file_param->galaxy_output($xml_writer); # where $file_param is a CPT::Parameter::*

Utilises the $xml_writer to add a <data> block in the <output> section

=head2 getopt_format

Returns the format character for a given CPT::Parameter::* type

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
