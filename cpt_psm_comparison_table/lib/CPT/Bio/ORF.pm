package CPT::Bio::ORF;
use strict;
use warnings;
use autodie;
use Moose;

has min_gene_length => (
	is          => 'rw',
	isa         => 'Int',
	default     => sub {
		0
	},
);
has sc_atg => ( is => 'rw', isa => 'Bool', default => sub { 1 } );
has sc_ttg => ( is => 'rw', isa => 'Bool', default => sub { 1 } );
has sc_ctg => ( is => 'rw', isa => 'Bool', default => sub { 0 } );
has sc_gtg => ( is => 'rw', isa => 'Bool', default => sub { 1 } );

our %code = (
	"TTT" => "F", "TTC" => "F", "TTA" => "L", "TTG" => "L", "TCT" => "S",
	"TCC" => "S", "TCA" => "S", "TCG" => "S", "TAT" => "Y", "TAC" => "Y",
	"TAA" => "*", "TAG" => "*", "TGT" => "C", "TGC" => "C", "TGA" => "*",
	"TGG" => "W", "CTT" => "L", "CTC" => "L", "CTA" => "L", "CTG" => "L",
	"CCT" => "P", "CCC" => "P", "CCA" => "P", "CCG" => "P", "CAT" => "H",
	"CAC" => "H", "CAA" => "Q", "CAG" => "Q", "CGT" => "R", "CGC" => "R",
	"CGA" => "R", "CGG" => "R", "ATT" => "I", "ATC" => "I", "ATA" => "I",
	"ATG" => "M", "ACT" => "T", "ACC" => "T", "ACA" => "T", "ACG" => "T",
	"AAT" => "N", "AAC" => "N", "AAA" => "K", "AAG" => "K", "AGT" => "S",
	"AGC" => "S", "AGA" => "R", "AGG" => "R", "GTT" => "V", "GTC" => "V",
	"GTA" => "V", "GTG" => "V", "GCT" => "A", "GCC" => "A", "GCA" => "A",
	"GCG" => "A", "GAT" => "D", "GAC" => "D", "GAA" => "E", "GAG" => "E",
	"GGT" => "G", "GGC" => "G", "GGA" => "G", "GGG" => "G",
);



sub run {
	my ($self, $sequence) = @_;
	# Read through forward strand
	my @putative_starts;

	# 30 seconds with a bioperl object
	# 5 seconds with string munging. >:|
	my $dna    = uc( $sequence );
	my $length = length($sequence);

	# Pre-create the regular expressions
	my ( $regex_forward, $regex_backwards );
	my $not_statement_f = '^';
	my $not_statement_r = '^';
	if ( !$self->sc_atg() ) {
		$not_statement_f .= 'A';
		$not_statement_r .= 'T';
	}
	if ( !$self->sc_ctg() ) {
		$not_statement_f .= 'C';
		$not_statement_r .= 'G';
	}
	if ( !$self->sc_ttg() ) {
		$not_statement_f .= 'T';
		$not_statement_r .= 'A';
	}
	if ( !$self->sc_gtg() ) {
		$not_statement_f .= 'G';
		$not_statement_r .= 'C';
	}

	# If any start is acceptable, we re-add them and remove our ^
	if($not_statement_r eq '^' && $not_statement_f eq '^'){
		$not_statement_f = 'ACTG';
		$not_statement_r = 'ACTG';
	}
	$regex_forward   = qr/[${not_statement_f}]TG/;
	$regex_backwards = qr/CA[${not_statement_r}]/;

	# Collect putative starts
	for ( my $i = 1 ; $i < $length - 1 ; $i++ ) {
		my $tri_nt = substr( $dna, $i - 1, 3 );    #$seq_obj->subseq($i,$i+2);
		if ( $tri_nt =~ $regex_forward ) {
			push( @putative_starts, [ $i, '+' ] );
		}
		if ( $tri_nt =~ $regex_backwards ) {
			push( @putative_starts, [ $i + 2, '-' ] );
		}
	}
	my %ORFs;

	#Loop through all of the starts we have
	my $fc = 0;
	my $rc = 0;
	foreach (@putative_starts) {
		my @putative_start = @{$_};

		my $final_seq = "";

		my $add;
		my $tri_nt;
		if ( $putative_start[1] eq "+" ) {
			my $end;
			for ( my $k = $putative_start[0] ; $k < $length ; $k = $k + 3 )
			{
				my $tri_nt = substr( $dna, $k, 3 );
				my $aa = $code{$tri_nt};
				if ( $aa && $aa ne '*' ) {
					$end = $k + 3;
					$final_seq .= $tri_nt;
				}
				else {
					last;
				}
			}
			if ( length($final_seq)/3 > $self->min_gene_length() ) {
				$ORFs{ 'f_' + $fc++ } = [
					length($final_seq)/3,
					$putative_start[0],
					$end,
					'F',
					$final_seq
				];
			}
		}    # - strand
		else {
			my $end;
			for ( my $k = $putative_start[0] ; $k >= 2 ; $k = $k - 3 ) {
				my $tmp = reverse( substr( $dna, $k - 3, 3 ) );

				$tmp =~ tr/ACTG/qzAC/;
				$tmp =~ tr/qz/TG/;

				my $aa = $code{$tmp};
				if ( defined $aa && $aa ne '*' ) {
					$end = $k - 1;
					$final_seq .= $tmp;
				}
				else {
					last;
				}

			}
			if ( length($final_seq)/3 > $self->min_gene_length() ) {
				$ORFs{ 'r_' + $rc++ } = [
					length($final_seq)/3,
					$end,
					$putative_start[0],
					'R',
					$final_seq
				];
			}
		}
	}

	my @orfs;

	for my $orf_key ( sort( keys(%ORFs) ) ) {
		my @tmp= @{ $ORFs{$orf_key} };
		my $seqobj = Bio::Seq->new(
			-display_id => sprintf(
				'orf%05d_%s',
				($orf_key + 1), $tmp[3],
			),
			-desc => sprintf(
				'[%s-%s; %s aa long]'
				,$tmp[1], $tmp[2], $tmp[0]
			),
			-seq => $tmp[4]
		);
		push(@orfs, $seqobj);
	}
	return @orfs;
}



no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::ORF

=head1 VERSION

version 1.99.4

=function run

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
