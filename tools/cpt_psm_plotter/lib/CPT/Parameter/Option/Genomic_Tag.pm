package CPT::Parameter::Option::Genomic_Tag;
use Moose;
with 'CPT::Parameter::Option';

my @validKeys = ( "-10_signal", "-35_signal", "3'UTR", "5'UTR", "CAAT_signal", "CDS", "C_region", "D-loop", "D_segment", "GC_signal", "J_segment", "LTR", "N_region", "RBS", "STS", "S_region", "TATA_signal", "V_region", "V_segment", "assembly_gap", "attenuator", "enhancer", "exon", "gap", "gene", "iDNA", "intron", "mRNA", "mat_peptide", "misc_RNA", "misc_binding", "misc_difference", "misc_feature", "misc_recomb", "misc_signal", "misc_structure", "mobile_element", "modified_base", "ncRNA", "old_sequence", "operon", "oriT", "polyA_signal", "polyA_site", "precursor_RNA", "prim_transcript", "primer_bind", "promoter", "protein_bind", "rRNA", "rep_origin", "repeat_region", "sig_peptide", "source", "stem_loop", "tRNA", "terminator", "tmRNA", "transit_peptide", "unsure", "variation", "whole", "all" );
my %validKeySet = map { $_ => $_ } @validKeys;

has 'options' => ( is => 'rw', isa => 'HashRef', default => sub { \%validKeySet } );


sub getopt_format {
	return '=s';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::Option::Genomic_Tag

=head1 VERSION

version 1.99.4

=head2 getopt_format

Returns the format character for a given CPT::Parameter::* type

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
