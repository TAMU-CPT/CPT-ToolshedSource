package CPT::Bio::GFF_Parsing;
use Moose;
use autodie;

my $tags = 'allele anticodon artificial_location
bio_material bound_moiety cell_line cell_type chromosome citation
clone clone_lib codon_start collected_by collection_date compare
country cultivar culture_collection db_xref dev_stage direction
EC_number ecotype environmental_sample estimated_length exception
experiment focus frequency function gap_type gene gene_synonym
germline haplogroup haplotype host identified_by inference isolate
isolation_source lab_host lat_lon linkage_evidence locus_tag
macronuclear map mating_type mobile_element_type mod_base mol_type
ncRNA_class note number old_locus_tag operon organelle organism
partial PCR_conditions PCR_primers phenotype plasmid pop_variant
product protein_id proviral pseudo rearranged replace
ribosomal_slippage rpt_family rpt_type rpt_unit_range rpt_unit_seq
satellite segment serotype serovar sex specimen_voucher
standard_name strain sub_clone sub_species sub_strain tag_peptide
tissue_lib tissue_type transgenic translation transl_except
transl_table trans_splicing variety';
my %valid_tags = map { $_ => 1 } split( /\s+/, $tags );

my $keys = "-10_signal -35_signal 3'UTR 5'UTR
CAAT_signal CDS C_region D-loop D_segment GC_signal J_segment LTR
N_region RBS STS S_region TATA_signal V_region V_segment
assembly_gap attenuator enhancer exon gap gene iDNA intron mRNA
mat_peptide misc_RNA misc_binding misc_difference misc_feature
misc_recomb misc_signal misc_structure mobile_element
modified_base ncRNA old_sequence operon oriT polyA_signal
polyA_site precursor_RNA prim_transcript primer_bind promoter
protein_bind rRNA rep_origin repeat_region sig_peptide source
stem_loop tRNA terminator tmRNA transit_peptide unsure variation";
my %valid_keys = map { $_ => 1 } split( /\s+/, $keys );

has 'tag_conv' => ( is => 'ro', isa => 'HashRef', default => sub { return {
	#tags
	'dbxref'   => 'db_xref',
	'parent'   => 'note',
	'name'     => 'label',
	'Name'     => 'label',
	'old-name' => 'obsolete_name',
	'id'       => 'note',
	'nat-host' => 'host',
	'genome'   => 'note',
	'region'   => 'source',
}; });


sub fix_gff_tag {
	my ($self, $tag) = @_;
	# Lowercase it
	if(defined $tag && defined(${$self->tag_conv()}{lc($tag)})){
		return ${$self->tag_conv()}{lc($tag)};
	}
	return $tag;
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::GFF_Parsing

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
