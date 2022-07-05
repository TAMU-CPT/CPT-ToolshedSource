package CPT::Writer::Fasta;
use Moose;
with 'CPT::Writer';
require Bio::SeqIO;

sub process {
	my ($self) = @_;
	$self->processed_data( $self->data );
	$self->processing_complete(1);
	return 1;
}

sub write {
	my ($self) = @_;
	if ( $self->processing_complete ) {
		$self->OutputFilesClass->extension( $self->suffix() );
		my $next_output_file = $self->OutputFilesClass->get_next_file();
		open( my $filehandle, '>', $next_output_file );
		# This is probably a good change but will need testing.
		if ( ref( $self->processed_data )  eq 'Bio::PrimarySeqI') {
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => 'Fasta',
			);
			$outseq->write_seq( $self->processed_data );
		}
		elsif ( ref( $self->processed_data )  eq 'ARRAY') {
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => 'Fasta',
			);
			foreach my $seq (@{$self->processed_data()}){
				$outseq->write_seq( $seq );
			}
		}
		else {
			print $filehandle $self->processed_data;
		}
		close($filehandle);
	}
	else {
		warn "Write called but processing was not marked as complete. Not writing";
	}
}

sub suffix {
	return 'fa';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Fasta

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
