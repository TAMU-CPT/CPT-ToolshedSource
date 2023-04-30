package CPT::Parameter::Float;
use Scalar::Util qw(looks_like_number);
use Moose;
with 'CPT::Parameter';

has 'min' => ( is => 'rw', isa => 'Num' );
has 'max' => ( is => 'rw', isa => 'Num' );


sub galaxy_input {
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('float');

	if(defined $self->min()){
		$params{min} = $self->min();
	}
	if(defined $self->max()){
		$params{max} = $self->max();
	}

	$xml_writer->startTag(
		'param',
		%params
	);
	$xml_writer->endTag('param');
	$self->handle_possible_galaxy_input_repeat_end($xml_writer);
}


sub galaxy_output {

}


sub validate_individual {
	my ($self, $value) = @_;
	if ( looks_like_number( $value ) ) {
		# Check bounds
		if ( defined $self->max() && $value > $self->max() ) {
			push(@{$self->errors()}, sprintf( "Value passed with %s was greater than the allowable upper bound. [%s > %s]", $self->name(), $value, $self->max() ));
			return 0;
		}
		if ( defined $self->min() && $value < $self->min() ) {
			push(@{$self->errors()}, sprintf( "Value passed with %s was smaller than the allowable minimum bound. [%s < %s]", $self->name(), $value, $self->min() ));
			return 0;
		}
		return 1;
	}
	else {
		push(@{$self->errors()}, sprintf( "Value passed with %s does not look like a float [%s]", $self->name(), $value ));
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

CPT::Parameter::Float

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
