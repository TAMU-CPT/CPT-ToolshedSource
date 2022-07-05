package CPT::Writer::YAML;
use Moose;
with 'CPT::Writer';

sub process {
	my ($self) = @_;
	require YAML::XS;
	$self->processed_data( YAML::XS::Dump( $self->data ) );
	$self->processing_complete(1);
}

sub suffix {
	return 'yml';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::YAML

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
