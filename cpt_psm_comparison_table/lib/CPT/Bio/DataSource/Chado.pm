package CPT::Bio::DataSource::Chado;
no warnings;
use Moose;
with 'CPT::Bio::DataSource';

has 'host' => ( is => 'rw', isa => 'Str' );
has 'pass' => ( is => 'rw', isa => 'Str' );
has 'user' => ( is => 'rw', isa => 'Str' );
has 'name' => ( is => 'rw', isa => 'Str' );
has 'port' => ( is => 'rw', isa => 'Str' );

has 'landmark' => ( is => 'rw', isa => 'Str' );
has 'organism' => ( is => 'rw', isa => 'Str' );


sub getSeqIO {
	my ($self) = @_;
	require CPT::Chado::GMOD_Conf;

	my $db = Bio::DB::Das::Chado->new(
		-dsn      => sprintf( 'dbi:Pg:dbname=%s;host=%s;port=%s', $self->name(), $self->host(), $self->port() ),
		-user     => $self->user(),
		-pass     => $self->pass(),
		-organism => $self->organism(),
		-inferCDS => 1,

	);

	# Get a list of "segments". Essentially (seqlen IS NOT NULL)
	my @segments = $db->segment( -name => $self->{'landmark'} );

	# TODO: Need to have a fallback method
	# Should only produce ONE since we specify landmark exactly
	foreach my $segment (@segments) {
		my $stream = $segment->get_feature_stream();
		use Bio::Seq;
		my $seq_obj = Bio::Seq->new(
			-seq        => $segment->seq->seq(),
			-display_id => $segment->id()
		);
		use Bio::SeqFeature::Generic;
		while ( my $feat = $stream->next_seq ) {

			# In an IDEAL world we'd just do $seq_obj->add_SeqFeature($feat);
			#
			# HOWEVER.
			#
			# ------------- EXCEPTION: Bio::Root::NotImplemented -------------
			# MSG: Abstract method "Bio::DB::Das::Chado::Segment::Feature::attach_seq" is not implemented by package Bio::DB::Das::Chado::Segment::Feature.
			# This is not your fault - author of Bio::DB::Das::Chado::Segment::Feature should be blamed!
			# STACK: Error::throw
			# STACK: Bio::Root::Root::throw /usr/local/share/perl/5.14.2/Bio/Root/Root.pm:472
			# STACK: Bio::Root::RootI::throw_not_implemented /usr/local/share/perl/5.14.2/Bio/Root/RootI.pm:748
			# STACK: Bio::DB::Das::Chado::Segment::Feature::attach_seq /usr/local/share/perl/5.14.2/Bio/DB/Das/Chado/Segment/Feature.pm:374
			# STACK: Bio::Seq::add_SeqFeature /usr/local/share/perl/5.14.2/Bio/Seq.pm:1148
			# STACK: chado_export.pl:59
			# ----------------------------------------------------------------

			# BUT WE CAN'T. >_>  rageface.tiff

			my %keys;
			foreach my $tag ( $feat->get_all_tags() ) {
				my @values = $feat->get_tag_values($tag);
				if ( $tag eq 'Note' ) {
					$tag = 'note';
				}
				if ( $tag eq 'Dbxref' ) {
					$tag = 'db_xref';

					#@values = map { if($_ ne 'GFF_source:Genbank'){ $_ } } @values;
					@values = grep !/GFF_source:Genbank/, @values;
				}
				$keys{$tag} = \@values;
			}

			#print $feat->gff_string(),"\n";
			my $new_feat = new Bio::SeqFeature::Generic(
				-start       => $feat->start(),
				-end         => $feat->end(),
				-strand      => $feat->strand(),
				-primary_tag => $feat->primary_tag(),
				-tag         => \%keys,
			);
			$seq_obj->add_SeqFeature($new_feat);
		}

		return $seq_obj;
	}

}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::DataSource::Chado

=head1 VERSION

version 1.99.4

=head2 getSeqIO

supposed to get a seqIO object from a chado DB. not fully implemented

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
