package CPT::Bio::RBS::Algo::Naive;
use Moose;
with 'CPT::Bio::RBS::Algo';
use CPT::Bio::RBS_Object;

my @SDs = (
	'aggaggt',
	'ggaggt',
	'aggagg',
	'aggag',
	'gaggt',
	'ggagg',
	'aggt',
	'gggt',
	'gagg',
	'gggg',
	'agga',
	'ggag',
	'gga',
	'gag',
	'agg',
	'ggt',
);

sub predict {
	my ( $self, %params ) = @_;
	my $upstream = $params{sequence};
	my $only_best = $params{return_best};

	my $length = length($upstream);

	my @results = ();
	foreach my $rbs ( @SDs ){
		while ($upstream =~ /$rbs/g) {
			# Position of regex match
			my $loc = $-[0];
			# Seq before RBS
			my $before = substr($upstream,0, $loc);
			# Seq after RBS
			my $after = substr($upstream, $loc + length($rbs));
			my $rbs_o = CPT::Bio::RBS_Object->new(
				upstream => sprintf('%s %s %s', $before , uc($rbs) , $after),
				score => $self->score_match($rbs, length($after)),
				rbs_seq => uc($rbs),
				separation => length($after),
			);
			push( @results, $rbs_o );
		}
	}
	@results = sort { $b->score() <=> $a->score() } @results;
	if (@results) {
		if($only_best){
			return ($results[0]);
		}else{
			return @results;
		}
	}
	else {
		return (
			CPT::Bio::RBS_Object->new(
				upstream =>$upstream,
				score => '-1',
				rbs_seq => 'None',
				separation => -1,
			)
		);
	}
}

sub score_match {
	my ($self, $match, $dist) = @_;
	return length($match);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::RBS::Algo::Naive

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
