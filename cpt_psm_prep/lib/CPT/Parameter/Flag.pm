package CPT::Parameter::Flag;
use Moose;
with 'CPT::Parameter';



sub galaxy_command {
	my ($self) = @_;
	my $value = $self->get_galaxy_command_identifier();

	# If it's hidden, specific to galaxy, and hidden from galaxy users,
	# then it is safe to assume we've specified a SANE default.
	if($self->hidden() && $self->_galaxy_specific()){
		$value = $self->default();
	}
	my $string;
	
	# If it's a repeat, we handle that
	$string .= $self->handle_possible_galaxy_command_repeat_start();
	# If it's required we set it to a value IF we have one. Otherwise value
	# will be the galaxy_identifier.
	if($self->required()){
		$string .= sprintf( '--%s' . "\n",
			$self->get_galaxy_cli_identifier()
		);
	}else{
		# If
		# This code is only relevant if we're multiple, otherwise the loop will
		# not pass here
		if ( !$self->multiple() ){
			$string .= sprintf('#if $%s:' . "\n",
				$self->get_galaxy_cli_identifier()
			);
		}
		# Flag
		$string .= sprintf( '--%s'."\n",
			$self->get_galaxy_cli_identifier(),
		);
		# End
		if ( !$self->multiple() ){
			$string .= "#end if\n";
		}
	}
	$string .= $self->handle_possible_galaxy_command_repeat_end();
	return $string;
}



sub galaxy_input {
	my ( $self, $xml_writer ) = @_;
	$self->handle_possible_galaxy_input_repeat_start($xml_writer);
	my %params = $self->get_default_input_parameters('boolean');
    $params{falsevalue} = 'False';
    $params{truevalue} = 'True';
    if($self->default()){
        $params{checked} = 'True';
    }else{
        $params{checked} = '';
    }
    # Remove value since we use "checked" here
    delete $params{value};

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
	return '';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::Flag

=head1 VERSION

version 1.99.4

=head2 galaxy_command

	$file_param->galaxy_command(); # where $file_param is a CPT::Parameter::*

Returns the portion of the command used in the <command/> block in galaxy XML files

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
