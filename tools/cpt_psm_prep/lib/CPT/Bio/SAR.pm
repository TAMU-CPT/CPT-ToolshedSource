package CPT::Bio::SAR;
use strict;
use warnings;
use autodie;
use Moose;

sub filter_sar {
	my ($self, @seqs) = @_;
	my @good;
	foreach(@seqs){
		if(has_sar_motif($_)){
			push(@good, $_);
		}
	}
	return @good;
}

sub has_sar_motif {
	my ( $self, $seq ) = @_;
	
	return 0 if(length $seq < 40);
	
	my $reg_a = qr/([^DEKR]{3}K[^DEKR]{8,}[^DER]{1}[^DEKR]{3})/;
	my $reg_b = qr/([KR]{1,}[^DEKR]{12,}[^DER]{1}[^DEKR]{3})/;

	my $first40 = substr( $seq, 0, 40 );

	# there is a transmembrane domain in the first 40 AAs
	# there is at least one positive charged AAs in front of the TMD
	if ( $first40 =~ $reg_a || $first40 =~ $reg_b ) {
		my $modi1st40 = $first40;
			# Cut out the match, and then add the whole thing to the end.
		my $t4homology =
			#substr($seq,0, $-[0] ), # Before the match
			#substr($seq, $-[0], ($+[0] - $-[0])), # the match
			substr($seq, $+[0]). # After the match
			$first40;
		$t4homology = substr($t4homology, 0 , 40);

		if ( $t4homology =~ qr/E[A-Z]{8}[DC][A-Z]{4,5}T/ ) {
			return 1;
		}
	}
	return 0;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::SAR

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
