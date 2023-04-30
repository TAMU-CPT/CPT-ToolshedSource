package CPT::Bio::Lipo;
use Moose;
use strict;
use warnings;
use Data::Dumper;
use autodie;

# ABSTRACT: Lipo finding functionality in a library.

sub run_hash {
	my ( $self, $hash_ref ) = @_;
	my %hash = %{$hash_ref};
	my @return_keys;
	foreach ( sort { $a <=> $b } keys %hash ) {
		if ( $hash{$_}[4] !~ qr/^.{10,39}C/ ) {
			next;
		}
		else {
			$hash{$_}[5] = $self->run_seq( $hash{$_}[4] );
		}
	}
	return \%hash;
}

sub run_seq {
	my ( $self, $seq ) = @_;
	my @C;    #A list of each C in the string, in str(10,40)
	for ( my $j = 10 ; $j < length($seq) && $j < 40 ; $j++ ) {
		if ( substr( $seq, $j, 1 ) =~ /[c]/i ) {
			push( @C, $j );
		}
	}
	my @results;
	for ( my $z = 0 ; $z < scalar(@C) ; $z++ ) {
		my $upC10 = "";

      #Make sure it's not ALL DEKRs 10 residues upstream. (Does that happen O.o)
		if ( substr( $seq, $C[$z] - 10, 10 ) !~ /[DEKR]/ ) {
			push(
				@results,
				[
					substr( $seq, 0, $C[$z] - 10 ),
					substr( $seq, $C[$z] - 10, 10 ),
					substr( $seq, $C[$z],      1 ),
					substr( $seq, $C[$z] + 1 ),
				]
			);
		}
	}
	if ( scalar @results ) {
		return \@results;
	}
	return undef;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::Lipo - Lipo finding functionality in a library.

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
