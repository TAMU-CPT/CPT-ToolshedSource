package CPT::Writer::GFF3;
use Moose;
with 'CPT::Writer';

sub process {
	my ($self) = @_;
	$self->processed_data( $self->data );
	$self->processing_complete(1);
}

sub suffix {
	return 'gff3';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::GFF3

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
