package CPT::Parameter::String;
use Moose;
with 'CPT::Parameter';


sub galaxy_input {
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('text');
	$xml_writer->startTag(
		'param',
		%params,
	);
	$xml_writer->endTag('param');
	$self->handle_possible_galaxy_input_repeat_end($xml_writer);
}


sub galaxy_output {

}


sub validate_individual {
	my ($self) = @_;
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

CPT::Parameter::String

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
