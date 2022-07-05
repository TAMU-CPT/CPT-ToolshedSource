package CPT::GBK2GFF3;
use strict;
use warnings;
use CPT;
use Data::Dumper;
use autodie;
use Bio::SeqIO;
use Moose;

has data => (
	is  => 'rw',
	isa => 'ArrayRef',
	default => sub { [] },
);
has header => (
	is  => 'rw',
	isa => 'ArrayRef',
);
has sequence => (
	is  => 'rw',
	isa => 'Str',
);
has seqid => (
	is  => 'rw',
	isa => 'Str',
);
has genbank => (
	is => 'rw',
	isa => 'Str',
);
has is_circular => (
	is => 'rw',
	isa => 'Str',
);
has id_prefix => ( is => 'rw', isa => 'Str' );
has global_feat_idx => ( is => 'rw', isa => 'Int', default => sub { 0 } );
has source => ( is => 'rw', isa => 'ArrayRef');

my %feat_type_count;
my %reserved_keys = map { $_ => 1 }
  qw/ID Name Alias Parent Target Gap Derives_from Note Dbxref Ontology_term/;

use CPT::Bio;
my $bio = CPT::Bio->new();
my %key_mapping = (
	"-"               => [ "located_sequence_feature",     "SO:0000110" ],
	"-10_signal"      => [ "minus_10_signal",              "SO:0000175" ],
	"-35_signal"      => [ "minus_35_signal",              "SO:0000176" ],
	"3'UTR"           => [ "three_prime_UTR",              "SO:0000205" ],
	"3'clip"          => [ "three_prime_clip",             "SO:0000557" ],
	"5'UTR"           => [ "five_prime_UTR",               "SO:0000204" ],
	"5'clip"          => [ "five_prime_clip",              "SO:0000555" ],
	"CAAT_signal"     => [ "CAAT_signal",                  "SO:0000172" ],
	"CDS"             => [ "CDS",                          "SO:0000316" ],
	"D-loop"          => [ "D_loop",                       "SO:0000297" ],
	"D_segment"       => [ "D_gene",                       "SO:0000458" ],
	"GC_signal"       => [ "GC_rich_region",               "SO:0000173" ],
	"LTR"             => [ "long_terminal_repeat",         "SO:0000286" ],
	"RBS"             => [ "ribosome_entry_site",          "SO:0000139" ],
	"STS"             => [ "STS",                          "SO:0000331" ],
	"TATA_signal"     => [ "TATA_box",                     "SO:0000174" ],
	"attenuator"      => [ "attenuator",                   "SO:0000140" ],
	"enhancer"        => [ "enhancer",                     "SO:0000165" ],
	"exon"            => [ "exon",                         "SO:0000147" ],
	"gap"             => [ "gap",                          "SO:0000730" ],
	"gene"            => [ "gene",                         "SO:0000704" ],
	"iDNA"            => [ "iDNA",                         "SO:0000723" ],
	"intron"          => [ "intron",                       "SO:0000188" ],
	"mRNA"            => [ "mRNA",                         "SO:0000234" ],
	"mat_peptide"     => [ "mature_protein_region",        "SO:0000419" ],
	"misc_RNA"        => [ "transcript",                   "SO:0000673" ],
	"misc_binding"    => [ "binding_site",                 "SO:0000409" ],
	"misc_difference" => [ "sequence_difference",          "SO:0000413" ],
	"misc_feature"    => [ "region",                       "SO:0000001" ],
	"misc_recomb"     => [ "recombination_feature",        "SO:0000298" ],
	"misc_signal"     => [ "regulatory_region",            "SO:0005836" ],
	"misc_structure"  => [ "sequence_secondary_structure", "SO:0000002" ],
	"modified_base"   => [ "modified_DNA_base",            "SO:0000305" ],
	"operon"          => [ "operon",                       "SO:0000178" ],
	"oriT"            => [ "origin_of_transfer",           "SO:0000724" ],
	"polyA_signal"    => [ "polyA_signal_sequence",        "SO:0000551" ],
	"polyA_site"      => [ "polyA_site",                   "SO:0000553" ],
	"precursor_RNA"   => [ "primary_transcript",           "SO:0000185" ],
	"prim_transcript" => [ "primary_transcript",           "SO:0000185" ],
	"primer_bind"     => [ "primer_binding_site",          "SO:0005850" ],
	"promoter"        => [ "promoter",                     "SO:0000167" ],
	"protein_bind"    => [ "protein_binding_site",         "SO:0000410" ],
	"rRNA"            => [ "rRNA",                         "SO:0000252" ],
	"repeat_region"   => [ "repeat_region",                "SO:0000657" ],
	"repeat_unit"     => [ "repeat_unit",                  "SO:0000726" ],
	"satellite"       => [ "satellite_DNA",                "SO:0000005" ],
	"scRNA"           => [ "scRNA",                        "SO:0000013" ],
	"sig_peptide"     => [ "signal_peptide",               "SO:0000418" ],
	"snRNA"           => [ "snRNA",                        "SO:0000274" ],
	"snoRNA"          => [ "snoRNA",                       "SO:0000275" ],
	"source"     => [ "contig",     "SO:0000149" ],    # manually modified
	"stem_loop"  => [ "stem_loop",  "SO:0000313" ],
	"tRNA"       => [ "tRNA",       "SO:0000253" ],
	"terminator" => [ "terminator", "SO:0000141" ],
	"transit_peptide" => [ "transit_peptide",  "SO:0000725" ],
	"variation"       => [ "sequence_variant", "SO:0000109" ],
);


sub get_gff3_file {
	my ($self) = @_;
	my @output;
	for my $header_line ( @{ $self->header() } ) {
		push( @output, $header_line );
	}
	push( @output, join( "\t", @{ $self->get_source } ) );
	for my $data_line ( @{ $self->data() }) {
		push( @output, join( "\t", @{$data_line} ) );
	}
	push( @output, '##FASTA' );
	push( @output, '>' . $self->seqid() );
	my $seq = $self->sequence();
	$seq =~ s/(.{80})/$1\n/g;
	push( @output, $seq );
	return join( "\n", @output );
}

sub escape {
	my ($self, $str) = @_;
	$str =~ s/,/%2C/g;
	$str =~ s/=/%3D/g;
	$str =~ s/;/%3B/g;
	$str =~ s/\t/%09/g;
	return $str;
}

sub FT_SO_map {
	my ( $self, $key ) = @_;
	if ( $key_mapping{$key} ) {
		my @result = @{ $key_mapping{$key} };
		return $result[0];
	}
	else {
		return 'region';
	}
}

sub source_map {
	my ( $self, $type ) = @_;
	if ( $self->{'override_source'} ) {
		return $self->{'override_source'};
	}
	if ( $self->{'annotation_software'}{$type} ) {
		return $self->{'annotation_software'}{$type};
	}
	else {
		return '.';
	}
}

sub get_attrs {
	my ( $self, %data ) = @_;
	my $feature     = $data{'feat'};
	my $parents_ref = $data{'parents'};

	my %attrs = ();
	$attrs{'ID'} =
	  $self->id_prefix() . '.' . ($self->global_feat_idx());

	$self->global_feat_idx($self->global_feat_idx()+1);

	# Handle Identifier
	my $identifier = $bio->_getIdentifier($feature);
	if ( $identifier ne 'ERROR' ) {
		$attrs{'Name'} = $identifier . '.' . $feature->primary_tag;
	}

	# Handle parents, if there are any
	if ($parents_ref) {
		if ( ref($parents_ref) eq 'ARRAY' ) {
			$attrs{'Parent'} = $parents_ref;
		}
		else {
			$attrs{'Parent'} = [$parents_ref];
		}
	}

       # These are otherwise "Special" keys that need to be handled differently.
	if ( $feature->has_tag('note') ) {
		my @notes = $feature->get_tag_values('note');
		$attrs{'Note'} = \@notes;
	}
	if ( $feature->has_tag('db_xref') ) {
		my @dbxref = $feature->get_tag_values('db_xref');
		$attrs{'Dbxref'} = \@dbxref;
	}

	# Do the rest
	for my $tag ( $feature->get_all_tags() ) {

		# If not one of the specially handled ones
		if ( $tag ne 'name' && $tag ne 'note' && $tag ne 'db_xref' ) {

			# If not a reserved_key
			if ( !$reserved_keys{$tag} ) {
				my @vals = $feature->get_tag_values($tag);
				$attrs{lc($tag)} = \@vals;
			}
			else {
				warn
"Trying to set a reserved key $tag with value $attrs{$tag}";
			}
		}
	}
	my %response = (
		id       => $attrs{'ID'},
		attr_str => $self->post_process_attribute_string(%attrs),
	);
	return %response;
}

sub post_process_attribute_string {
	my ($self,%attrs) = @_;
	my @parts = ();
	for my $k ( keys %attrs ) {

		# IGNORED TAGS
		if ( $k ne 'translation' && $k ne 'product' ) {
			my $joined =
			  $self->escape_and_join_attribute_subpart( $attrs{$k} );
			push @parts, "$k=$joined";
		}
	}

	#print STDERR join("\t",@parts),"\n";
	return join( ";", @parts );

}

sub escape_and_join_attribute_subpart {
	my ($self,$ref) = @_;
	if ( ref($ref) eq 'ARRAY' ) {
		my @attrs = @{$ref};
		return join( ",", map { $self->escape($_) } @attrs );
	}
	else {    #scalar
		return $self->escape($ref);
	}
}

sub get_source {
	my ($self) = @_;
	if ( !$self->source() ) {
		$self->auto_source();
	}
	return $self->source();
}

sub auto_source {

	# Auto generate a source feature, in case there isn't one.
	my ($self) = @_;
	my @region = (
		$self->seqid(),
		( $self->genbank() ? 'Genbank' : 'Assembly' ),
		'contig',
		1,
		$self->get_length,
		'.',
		'.',
		'.',
		sprintf( "ID=%s;Name=%s", $self->seqid(), $self->seqid() )
		  . ( $self->is_circular() ? ";Is_circular=True" : "" )
	);
	$self->source(\@region);
}

sub add_feature {
	my ( $self, $feat ) = @_;
	my $primary_tag = $feat->primary_tag;
	if ( $primary_tag eq 'CDS' ) {
		my ( $id, $data_0 ) = $self->_add_gene( feat => $feat, );
		my ($data_1) = $self->_add_feature(
			feat   => $feat,
			parent => $id,
		);
		$self->_low_level_add_feature($data_0);
		$self->_low_level_add_feature($data_1);
	}
	elsif ( $primary_tag eq 'source' ) {
		my ($data) = $self->_add_feature( feat => $feat, );

		# YUCK.
		my @z     = @{$data};
		my $seqid = $self->seqid();
		$z[8] =~ s/ID=[^;]*;/ID=$seqid;/g;
		$self->source( \@z );
	}
	elsif ( $primary_tag ne 'gene' ) {
		my ($data) = $self->_add_feature( feat => $feat, );
		$self->_low_level_add_feature($data);
	}

}

sub _low_level_add_feature {
	my ( $self, $data ) = @_;
	push( @{ $self->data() }, $data );
}

sub _add_feature {
	my ( $self, %data ) = @_;
	my %attrs =
	  $self->get_attrs( feat => $data{feat}, parents => $data{parent} );
	my @data = (
		$self->seqid(),
		$self->source_map( $data{feat}->primary_tag ),
		$self->FT_SO_map( $data{feat}->primary_tag ),
		$data{feat}->start,
		$data{feat}->end,
		'.',
		( $data{feat}->strand == 1 ? '+' : '-' ),
		'.',
		$attrs{attr_str}
	);

	#$self->_low_level_add_feature(\@data);
	return \@data;
}

sub _add_gene {
	my ( $self, %data ) = @_;
	my $id = $self->id_prefix() . '.' . ( $self->global_feat_idx());
	$self->global_feat_idx($self->global_feat_idx()+1);
	my $gene_count = ++$feat_type_count{'gene'};
	my @data       = (
		$self->seqid(),
		$self->source_map( $data{feat}->primary_tag ),
		$self->FT_SO_map('gene'),
		$data{feat}->start,
		$data{feat}->end,
		'.',
		( $data{feat}->strand == 1 ? '+' : '-' ),
		'.',
		"ID=$id;Name=Gene$gene_count"
	);

	#$self->_low_level_add_feature(\@data);
	return ( $id, \@data );
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::GBK2GFF3

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
