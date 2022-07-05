package CPT::Parameter::Option;
use Moose::Role;
use strict;
use warnings;
use autodie;
with 'CPT::Parameter';

has 'options' => ( is => 'rw', isa => 'HashRef' );
# stored as {short => "some long text"}


sub galaxy_input {
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('select');
	$xml_writer->startTag(
		'param',
        %params,
	);
	my %options = %{ $self->options() };
	foreach ( sort( keys(%options)) ) {
        my %p = (value => $_);
        if(defined $_  && defined $self->default() && $_ eq $self->default()){
            $p{selected} = 'True';
        }
		$xml_writer->startTag( 'option', %p);
		$xml_writer->characters( $options{$_} );
		$xml_writer->endTag('option');
	}
	$xml_writer->endTag('param');
	$self->handle_possible_galaxy_input_repeat_end($xml_writer);
}


sub galaxy_output {

}

sub validate_individual {
	my ($self, $val) = @_;
	my %options = %{ $self->options() };
	if($options{$val}){
		return 1;
	}{
		push(@{$self->errors()}, sprintf( "Unknown value [%s] supplied to a option %s", $val,$self->name()));
		return 0;
	}
}


sub getopt_format {
	return '=s';
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::Option

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
