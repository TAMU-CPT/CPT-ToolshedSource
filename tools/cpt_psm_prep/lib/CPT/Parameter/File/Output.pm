package CPT::Parameter::File::Output;
use Moose;
with 'CPT::Parameter';
use CPT::OutputFiles;

# Has the user requested that the format is ALWAYS of a specific type. This is
# useful when (e.g,.) CSV output is required because it's part of a pipeline.
# Of course, in a perfect world that wouldn't be necessary as we'd be able to
# read in data and the only constraint would be that it was "text/tabular" and
# magically we'd have a hash just like we would with CSV. Sigh....
has 'hardcoded' => ( is => 'rw', isa => 'Bool' );
# The format of the internal data structure that we're pushing to output
# See CPT.pm for a list of these (under %acceptable)
has 'data_format' => ( is => 'rw', isa => 'Str' );
has 'default_format' => ( is => 'rw', isa => 'Str' );

# registered => ['text/tabular~CSV', 'text/plain=TXT'],
has 'registered_types' => ( is => 'rw', isa => 'ArrayRef' );
has 'cpt_outputfile_data_access' => ( is => 'ro', isa => 'Any', default => sub { CPT::OutputFiles->new() } );



sub galaxy_input {

	# Required by our parent. For an output file, this is non-functional
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('select');
	$params{label} = 'Format of ' . $self->get_galaxy_cli_identifier(),
	$params{name} = sprintf( "%s_%s", $self->get_galaxy_cli_identifier, 'format' ),
	# Remove any default values for galaxy
	delete $params{value};
	$xml_writer->startTag(
		'param',
		%params,
	);

	if(defined $self->data_format()){

		foreach ( sort @{ $self->cpt_outputfile_data_access()->valid_formats($self->data_format()) } ) {
			my %p = (value => $_);
			if($_ eq $self->default_format()){
				$p{selected} = 'True';
			}
			$xml_writer->startTag( 'option', %p );
			$xml_writer->characters( $_ );
			$xml_writer->endTag('option');
		}
	}else{
		$xml_writer->startTag( 'option', value => 'data', selected => 'True' );
		$xml_writer->characters( 'data' );
		$xml_writer->endTag('option');
	}
	$xml_writer->endTag('param');
	$self->handle_possible_galaxy_input_repeat_end($xml_writer);
}


sub galaxy_output {
	my ( $self, $xml_writer ) = @_;
	my $format;
	if(defined $self->default_format()){
		$format = $self->default_format();
	}else{
		$format = 'data';
	}

	$xml_writer->startTag(
		'data',
		name   => $self->get_galaxy_cli_identifier(),
		format => $format,
	);

	if ( !$self->hardcoded() ) {
		$xml_writer->startTag('change_format');
		# Otherwise it's still going to be set as the default_format so we're not toooo worried.
		if(defined($self->data_format())){
			my @galaxy_formats = @{ $self->cpt_outputfile_data_access()->valid_formats($self->data_format()) };
			foreach (sort @galaxy_formats) {
				$xml_writer->startTag(
					'when',
					input  => sprintf( "%s_%s", $self->get_galaxy_cli_identifier, 'format' ),
					value  => $_,
					format => $self->cpt_outputfile_data_access()->get_format_mapping($_),
				);
				$xml_writer->endTag('when');
			}
		}
		$xml_writer->endTag('change_format');
	}
	$xml_writer->endTag('data');
}

sub validate_individual {
	my ($self, $val) = @_;
	#if(! -e $self->value()){
	#	return 1;
	#}
	#return 0;
	return 1;
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

CPT::Parameter::File::Output

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
