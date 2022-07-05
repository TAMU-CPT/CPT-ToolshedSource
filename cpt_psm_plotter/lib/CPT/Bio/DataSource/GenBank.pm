package CPT::Bio::DataSource::GenBank;
no warnings;
use Moose;
with 'CPT::Bio::DataSource';

has 'file' => ( is => 'rw', isa => 'Str' );


sub getSeqIO {
	my ($self) = @_;
	use Bio::SeqIO;
	my $seqio = Bio::SeqIO->new(
		-file   => $self->file(),
		-format => 'GenBank',
	);
	my @results;
	return $seqio;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::DataSource::GenBank

=head1 VERSION

version 1.99.4

=head2 getSeqIO

	$gbk_ds->getSeqIO();

supposed to return a genabnk DS. Not tested.

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
