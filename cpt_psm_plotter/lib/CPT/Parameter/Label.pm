package CPT::Parameter::Label;
use Moose;
with 'CPT::Parameter';

has 'label' => (is => 'rw', isa => 'Str');
has 'name' => (is => 'rw', isa => 'Any');

sub getOptionsArray{
	my ($self) = @_;
	return [$self->label()];
}
sub validate_individual{
	return 1;
}

sub galaxy_input{
	return;
}
sub galaxy_output{
	return;
}
sub galaxy_command{
    return;
}
sub getopt_format{
    return '';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::Label

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
