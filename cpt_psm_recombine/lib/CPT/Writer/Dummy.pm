package CPT::Writer::Dummy;
use Moose;
with 'CPT::Writer';

sub process {
	my ($self) = @_;
	$self->processed_data( $self->data );
	$self->processing_complete(1);
}

sub write {
	my ($self) = @_;
	# Do nothing. This object sees/hears nothing.
	# Except we would like to consume a single filename
	push(@{$self->used_filenames()}, $self->OutputFilesClass->get_next_file());
	return;
}

sub suffix {
	return 'txt';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Dummy

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
