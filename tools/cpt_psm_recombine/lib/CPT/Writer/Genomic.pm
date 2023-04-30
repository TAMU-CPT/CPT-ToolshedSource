package CPT::Writer::Genomic;
use Moose;
with 'CPT::Writer';

# Specific format of genomic writer
has 'format' => ( is => 'rw', isa => 'Str', default => 'Genbank');

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
		
		require Bio::SeqIO;
		my $obj_type = ref $self->processed_data();
		if(substr($obj_type,0,10) eq 'Bio::Seq::'){
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => $self->format(),
			);
			$outseq->write_seq( $self->processed_data );
		}elsif(substr($obj_type,0,10) eq 'Bio::SeqIO'){
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => $self->format(),
			);
			while (my $inseq = $self->processed_data()->next_seq()) {
				$outseq->write_seq($inseq);
			}
		}elsif(substr($obj_type,0,8) eq 'Bio::Seq'){
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => $self->format(),
			);
			$outseq->write_seq( $self->processed_data );
		}elsif(ref $self->processed_data eq 'ARRAY'){
			# Assume array of genomes
			my $outseq = Bio::SeqIO->new(
				-fh     => $filehandle,
				-format => $self->format(),
			);
			foreach my $inseq(@{$self->processed_data}){
				$outseq->write_seq($inseq);
			}
		}else{
			print $filehandle $self->processed_data();
		}
		close($filehandle);
	}
	else {
		warn
"Write called but processing was not marked as complete. Not writing";
	}
}

sub suffix {
	my ($self) = @_;
	my %suffix_map = (
		'abi'        => 'abi',
		'ace'        => 'ace',
		'agave'      => 'agave',
		'alf'        => 'alf',
		'asciitree'  => 'txt',
		'bsml'       => 'bsml',
		'bsml_sax'   => 'bsml',
		'chadoxml'   => 'xml',
		'chaos'      => 'chaos',
		'chaosxml'   => 'xml',
		'ctf'        => 'ctf',
		'embl'       => 'emb',
		'entrezgene' => 'asn1',
		'excel'      => 'xls',
		'exp'        => 'exp',
		'fasta'      => 'fa',
		'fastq'      => 'fastq',
		'game'       => 'xml',
		'gcg'        => 'gcg',
		'genbank'    => 'gbk',
		'interpro'   => 'xml',
		'kegg'       => 'kegg',
		'largefasta' => 'lfa',
		'lasergene'  => 'lasergene',
		'locuslink'  => 'll_tmpl',
		'phd'        => 'phred',
		'pir'        => 'pir',
		'pln'        => 'pln',
		'qual'       => 'phred',
		'raw'        => 'txt',
		'scf'        => 'scf',
		'seqxml'     => 'xml',
		'strider'    => 'strider',
		'swiss'      => 'sp',
		'tab'        => 'tsv',
		'tigr'       => 'xml',
		'tigrxml'    => 'xml',
		'tinyseq'    => 'xml',
		'ztr'        => 'ztr',
	);

	if($suffix_map{lc($self->format())}){
		return $suffix_map{lc($self->format())};
	}else{
		return 'unknown';
	}
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Genomic

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
