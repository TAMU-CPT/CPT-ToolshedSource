package CPT::Bio::RBS;
use Moose;
use autodie;

has 'algo'      => ( is => 'rw', isa => 'Str' );
has 'predictor' => ( is => 'rw', isa => 'Any' );
has 'only_best' => ( is => 'rw', isa => 'Bool', default => sub { 0 } );

sub set_algorithm {
	my ( $self, $algorithm ) = @_;
	if ( $algorithm eq 'naive' ) {
		use CPT::Bio::RBS::Algo::Naive;
		my $a = CPT::Bio::RBS::Algo::Naive->new();
		$self->predictor($a);
	}
	else {
		die 'Algorithm not implemented';
	}
}

# Run the prediction on the sequence
sub predict {
	my ( $self, $sequence ) = @_;
	return $self->predictor()->predict(
		sequence => lc($sequence),
		return_best => $self->only_best(),
	);
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::RBS

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
