package CPT::BioData;
use Moose;
use strict;
use warnings;
use autodie;

has 'dummy_var' => (isa => 'Str', is => 'ro');

my %genbank_feature_tags = (
	"locus_tag"            => 1,
	"gene"                 => 1,
	"product"              => 1,
	"allele"               => 1,
	"anticodon"            => 1,
	"artificial_location"  => 1,
	"bio_material"         => 1,
	"bound_moiety"         => 1,
	"cell_line"            => 1,
	"cell_type"            => 1,
	"chromosome"           => 1,
	"citation"             => 1,
	"clone"                => 1,
	"clone_lib"            => 1,
	"codon_start"          => 1,
	"collected_by"         => 1,
	"collection_date"      => 1,
	"compare"              => 1,
	"country"              => 1,
	"cultivar"             => 1,
	"culture_collection"   => 1,
	"db_xref"              => 1,
	"dev_stage"            => 1,
	"direction"            => 1,
	"EC_number"            => 1,
	"ecotype"              => 1,
	"environmental_sample" => 1,
	"estimated_length"     => 1,
	"exception"            => 1,
	"experiment"           => 1,
	"focus"                => 1,
	"frequency"            => 1,
	"function"             => 1,
	"gap_type"             => 1,
	"gene_synonym"         => 1,
	"germline"             => 1,
	"haplogroup"           => 1,
	"haplotype"            => 1,
	"host"                 => 1,
	"identified_by"        => 1,
	"inference"            => 1,
	"isolate"              => 1,
	"isolation_source"     => 1,
	"lab_host"             => 1,
	"lat_lon"              => 1,
	"linkage_evidence"     => 1,
	"macronuclear"         => 1,
	"map"                  => 1,
	"mating_type"          => 1,
	"mobile_element_type"  => 1,
	"mod_base"             => 1,
	"mol_type"             => 1,
	"ncRNA_class"          => 1,
	"note"                 => 1,
	"number"               => 1,
	"old_locus_tag"        => 1,
	"operon"               => 1,
	"organelle"            => 1,
	"organism"             => 1,
	"partial"              => 1,
	"PCR_conditions"       => 1,
	"PCR_primers"          => 1,
	"phenotype"            => 1,
	"plasmid"              => 1,
	"pop_variant"          => 1,
	"protein_id"           => 1,
	"proviral"             => 1,
	"pseudo"               => 1,
	"rearranged"           => 1,
	"replace"              => 1,
	"ribosomal_slippage"   => 1,
	"rpt_family"           => 1,
	"rpt_type"             => 1,
	"rpt_unit_range"       => 1,
	"rpt_unit_seq"         => 1,
	"satellite"            => 1,
	"segment"              => 1,
	"serotype"             => 1,
	"serovar"              => 1,
	"sex"                  => 1,
	"specimen_voucher"     => 1,
	"standard_name"        => 1,
	"strain"               => 1,
	"sub_clone"            => 1,
	"sub_species"          => 1,
	"sub_strain"           => 1,
	"tag_peptide"          => 1,
	"tissue_lib"           => 1,
	"tissue_type"          => 1,
	"transgenic"           => 1,
	"translation"          => 1,
	"transl_except"        => 1,
	"transl_table"         => 1,
	"trans_splicing"       => 1,
	"variety"              => 1,
);
my %artemis_colours = (
	0  => 'rgb(255,255,255)',
	1  => 'rgb(100,100,100)',
	2  => 'rgb(255,0,0)',
	3  => 'rgb(0,255,0)',
	4  => 'rgb(0,0,255)',
	5  => 'rgb(0,255,255)',
	6  => 'rgb(255,0,255)',
	7  => 'rgb(255,255,0)',
	8  => 'rgb(152,251,152)',
	9  => 'rgb(135,206,250)',
	10 => 'rgb(255,165,0)',
	11 => 'rgb(200,150,100)',
	12 => 'rgb(255,200,200)',
	13 => 'rgb(170,170,170)',
	14 => 'rgb(0,0,0)',
	15 => 'rgb(255,63,63)',
	16 => 'rgb(255,127,127)',
	17 => 'rgb(255,191,191)',
);

sub artemis_colour_decode{
	my ($self, $idx) = @_;
	return $artemis_colours{$idx};
}

my %table321 = (
	'Gly' => 'G', 'Pro' => 'P',
	'Ala' => 'A',
	'Val' => 'V',
	'Leu' => 'L',
	'Ile' => 'I',
	'Met' => 'M',
	'Cys' => 'C',
	'Phe' => 'F',
	'Tyr' => 'Y',
	'Trp' => 'W',
	'His' => 'H',
	'Lys' => 'K',
	'Arg' => 'R',
	'Gln' => 'Q',
	'Asn' => 'N',
	'Glu' => 'E',
	'Asp' => 'D',
	'Ser' => 'S',
	'Thr' => 'T',
	'XXX' => 'X',
	'End' => '*',
	'Stop' => '*'
);

sub decode321{
	my ($self, $three) = @_;
	return $table321{$three};
}


sub get321Table {
	my ($self) = @_;
	return \%table321;
}


sub getTranslationTable {
	my ($self, $table_id) = @_;
	require Bio::Tools::CodonTable;
	my $table = Bio::Tools::CodonTable->new( -id => (defined $table_id? $table_id: 1) );
	my %result;
	my @codons = qw(A C T G);
	foreach my $i (@codons) {
		foreach my $j (@codons) {
			foreach my $k (@codons) {
				$result{"$i$j$k"} = $table->translate("$i$j$k");
			}
		}
	}
	if(defined($table_id) && $table_id == 11){
		$result{TGA} = '*';
		$result{TAA} = '#';
		$result{TAG} = '+';
	}
	return \%result;
}



sub isValidTag {
    my ( $self, $tag ) = @_;
    return $genbank_feature_tags{$tag};
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::BioData

=head1 VERSION

version 1.99.4

=head2 get321Table

	$bio->get321Table();

Convenience function which returns a codon translation table (3 letter ID to 1 letter code)

=head2 getTranslationTable

	$bio->getTranslationTable();

Convenience function which returns a hash translated according to Bio::Tools::CodonTable

This is done for speed reasons. CodonTable is very slow and we require better performance

=head2 isValidTag

    if($cptbio->isValidTag('locus_tag')) { ... }

Will validate a GBK feature tag

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
