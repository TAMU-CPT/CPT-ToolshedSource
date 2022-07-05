package CPT::Bio;
use Moose;
use strict;
use warnings;
use autodie;
use CPT::FiletypeDetector;
use CPT::BioData;
my $bd = CPT::BioData->new();

my $filetype = CPT::FiletypeDetector->new();

has 'var_translate' => ( is => 'rw', isa => 'Bool');
has 'var_header' => ( is => 'rw', isa => 'Bool');
has codonTable => (
	is	    => 'rw',
	isa 	=> 'Any',
	default => sub {
		$bd->getTranslationTable(11)
	},
);

sub set_codon_table {
	my ($self, $num) = @_;
	$self->codonTable($bd->getTranslationTable($num));
}


sub _getFeatureTag {
	my ( $self, $feat, $tag ) = @_;
	if(! defined($feat)){
		warn "Undefined feature";
	}
	return $feat->has_tag($tag)
	  ? ( join( ',', $feat->get_tag_values($tag) ) )
	  : '';
}

sub _getIdentifier {
	my ( $self, $feat ) = @_;
	my $line;
	if ( ref $feat eq 'Bio::Seq::RichSeq' || ref $feat eq 'Bio::Seq' ) {
		return $feat->display_id;
	}
	else {
		my $locus_tag = $self->_getFeatureTag( $feat, 'locus_tag' );
		if ($locus_tag) {
			return $locus_tag;
		}
		my $gene = $self->_getFeatureTag( $feat, 'gene' );
		if ($gene) {
			return $gene;
		}
		my $product = $self->_getFeatureTag( $feat, 'product' );
		if ($product) {
			return $product;
		}
	}
	return sprintf("%s_%s_%s", $feat->start(), $feat->end(), ($feat->strand() == 1 ? 'sense':'antisense'));
}


sub requestCopy {
	my ( $self, %data ) = @_;
	use Bio::SeqIO;
	if ($data{'file'} ) {
		my ($guessed_type) = $filetype->detect( $data{'file'} );
		my $seqio = Bio::SeqIO->new(
			-file   => $data{'file'},
			-format => $guessed_type
		);
		my @results;
		while ( my $seqobj = $seqio->next_seq() ) {
			return \$seqobj;
		}
	}
	else {
		die "No file specified";
	}
}


sub getSeqIO {
	my ( $self, $file ) = @_;
	use Bio::SeqIO;
	if ($file ) {
		my ($guessed_type) = $filetype->detect( $file );
		my $seqio = Bio::SeqIO->new(
			-file   => $file,
			-format => $guessed_type
		);
		return $seqio;
	}
	else {
		die "No file specified";
	}
}


sub parseFile {
	my ( $self, %data ) = @_;
	use Bio::SeqIO;

	my ($guessed_type) = $filetype->detect( $data{'file'} );
	my $seqio = Bio::SeqIO->new(
		-file   => $data{'file'},
		-format => $guessed_type
	);

	# Are we to translate this
	$self->var_translate(defined($data{translate}) && $data{translate});
	$self->var_header(defined($data{header}) && $data{header});

	my @results;
	if ( not defined $data{'subset'} ) {
		$data{'subset'} = 'all';
	}
	while ( my $seqobj = $seqio->next_seq() ) {
		if (
			(ref $data{'subset'} ne 'ARRAY'
			&& $data{'subset'} eq 'whole' ) # Want the whole thing for a richseq
			||
			(ref $seqobj eq 'Bio::Seq' || ref $seqobj eq 'Bio::Seq::fasta')
			# or it's a fasta type sequence
		)
		{
			push( @results, $self->handle_seq($seqobj));
		}
		else                    #data subset eq sometag
		{
			my %wanted_tags;
			if ( ref $data{'subset'} eq 'ARRAY' ) {
				%wanted_tags =
				  map { $_ => 1 } @{ $data{'subset'} };
			}
			else {
				$wanted_tags{ $data{'subset'} }++;
			}
			foreach my $feat ( $seqobj->get_SeqFeatures ) {
				if (
					$wanted_tags{ $feat->primary_tag }
					|| (       $wanted_tags{'all'}
						&& $feat->primary_tag ne
						"source" )
				  )
				{
					push( @results, $self->handle_seq($feat));
				}
			}
		}
	}
	if ( $data{'callback'} ) {
		$data{'callback'}->( \@results );
	}
	else {
		return \@results;
	}
}

sub handle_seq {
	my ($self, $obj) = @_;

	my @line;
	if ( $self->var_header() ){
		$line[0] = '>' . $self->_getIdentifier($obj);
	}
	
	# Get our sequence
	$line[1] = $self->intelligent_get_seq($obj);

	if ( $self->var_translate() ) {
		$line[1] = $self->translate($line[1]);
	}
	return \@line;
}

sub intelligent_get_seq {
	my ($self, $obj, %extra) = @_;
	# Top level, e.g., fasta/gbk file, "extra" doesn't apply to these
	if ( ref $obj eq 'Bio::Seq::RichSeq' || ref $obj eq 'Bio::Seq' ) {
		return $obj->seq;
	}else{
		return $self->get_seq_from_feature($obj, %extra);
	}
}
sub get_seq_from_feature {
	my ($self, $feat, %extra) = @_;
	my $seq;
	my $l;
	if($extra{parent}){
		$l = $extra{parent}->length();
	}

	if($extra{upstream}){
		if($feat->strand < 0){
			my $y = $feat->end + 1;
			my $z = $feat->end + $extra{upstream};
			if($y < $l){
				if($z > $l){
					$z = $l;
				}
				$seq .= $extra{parent}->trunc($y, $z)->revcom->seq;
			}
		}else{
			my $y = $feat->start - $extra{upstream};
			my $z = $feat->start - 1;
			if($z > 0){
				if($y < 1){
					$y = 1;
				}
				$seq .= $extra{parent}->trunc($y, $z)->seq;
			}
		}
	}
	if(ref($feat->location) eq 'Bio::Location::Simple'){
		$seq .= $feat->seq->seq();
	}else{
		$seq .= $feat->spliced_seq->seq();
	}
	if($extra{downstream}){
		if($feat->strand < 0){
			my $y = $feat->start - $extra{downstream};
			my $z = $feat->start - 1;
			if($z > 0){
				if($y < 1){
					$y = 1;
				}
				$seq .= $extra{parent}->trunc($y, $z)->revcom->seq;
			}
		}else{
			my $y = $feat->end + 1;
			my $z = $feat->end + $extra{downstream};
			if($y < $l){
				if($z > $l){
					$z = $l;
				}
				$seq .= $extra{parent}->trunc($y, $z)->seq;
			}
		}
	}

	return $seq;
}


sub translate {
	my ($self, $seq) = @_;
	if($seq =~ /^[ACTGN]+$/){
		my %ct = %{$self->codonTable};
		$seq  = join( '' , map { if($ct{$_}){ $ct{$_} }else{ () } } unpack("(A3)*", $seq));
	}
	return $seq;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio

=head1 VERSION

version 1.99.4

=head2 _getFeatureTag

	my $tag = $libCPT->_getFeatureTag($feature,'note');

returns all values of the given tag, joined with ','.

=head2 requestCopy

	my $seqobj = $libCPT->requestCopy('file'=>'test.gbk');

requests a 'copy' of a given Bio::SeqIO file, which allows for addition of features before writing out to file.

=head2 getSeqIO

	my $seqio = $libCPT->getSeqIO('file'=>'test.gbk');

requests a 'copy' of a given Bio::SeqIO file, which allows for addition of features before writing out to file.

=head2 parseFile

	$libCPT->parseFile(
		'file'      => $options{'file'},
		'callback'  => \&func,
		'translate' => 1,
		'header'    => 1,
		'subset'    => ['CDS', $options{'tag'}],
	);

Arguably the most important function in this library, wraps a lot of functionality in a clean wrapper, since most of the scripts we have are written around data munging.

=over 4

=item *

file - the Bio::SeqIO file to process

=item *

callback - the function to send our data to. Done all at once, in an array

=item *

translate - should we translate the sequence to amino acids if it's not already.

=item *

subset - either "whole", a valid tag, or an array of valid tags

=item *

header - Do we want a header (FASTA) with our result set

=back

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
