package CPT::Bio::NW_MSA;
use Moose;
use strict;
use warnings;
use autodie;
use List::Util qw(max);

has 'sequences' => ( is => 'rw', isa => 'ArrayRef');
# If true, relationships are assumed to be bidirectional
has 'bidi' => (is => 'rw', isa => 'Bool');
has 'relationships' => ( is => 'rw', isa => 'HashRef', default => sub { {} });
#
has 'verbose' => ( is => 'rw', isa => 'Num');
#
has 'gap_penalty' => ( is => 'rw', isa => 'Num');
has 'match_score' => ( is => 'rw', isa => 'Num');
has 'mismatch_score' => ( is => 'rw', isa => 'Num');

# local stuff
#has 'current_list' => ( is => 'rw', isa => 'ArrayRef');
has 'merger' => (is => 'rw', isa => 'HashRef');
has 'number_of_aligned_lists' => ( is => 'rw', isa => 'Num', default => sub { 0 });

sub add_relationship {
	my ($self, $from, $to) = @_;
	${$self->relationships()}{$from}{$to} = 1;
	if($self->bidi()){
		${$self->relationships()}{$to}{$from} = 1;
	}
}

sub Sij {
	my($self, $merger_row, $query) = @_;
	# Comparing a query against a merger row
	my @check_against = @{$merger_row};
	#print "Checking " . join(",",@check_against) .":$query\t";
	foreach(@check_against){
		if(${$self->relationships()}{$query}{$_}
			|| ${$self->relationships()}{$_}{$query}){
			#print $self->match_score() . "\n";
			return $self->match_score();
		}
	}
	#print $self->mismatch_score() . "\n";
	return $self->mismatch_score();
}

sub align_list {
	my ($self, $list_ref) = @_;
	# If we haven't aligned any lists, we do something special
	if($self->number_of_aligned_lists() == 0){
		# Pretend we've aligned ONE list already
		$self->number_of_aligned_lists(1);
		my @list = @{$list_ref};
		# Fake the merger
		my %merger;
		for(my $i = 0; $i < scalar @list; $i++){
			$merger{$i} = [$list[$i]];
		}
		$self->merger(\%merger);
	}else{
		$self->find_best_path($self->merger(), $list_ref);
		$self->number_of_aligned_lists($self->number_of_aligned_lists() + 1);
	}
}

sub find_best_path {
	my ($self, $merger_ref, $list_ref) = @_;
	my %merger = %{$merger_ref};
	my @list = @{$list_ref};

	my $max_i = scalar(keys(%merger));
	my $max_j = scalar(@list);

	my %score_mat;
	my %point_mat;

	# Initial zeros for matrices
	$point_mat{0}{0} = 'DONE';
	$score_mat{0}{0} = 0;

	for(my $a = 1; $a <= $max_i; $a++){
		$point_mat{$a}{0} = 'U';
		$score_mat{$a}{0} = $self->gap_penalty();
	}
	for(my $b = 1; $b <= $max_j; $b++){
		$point_mat{0}{$b} = 'L';
		$score_mat{0}{$b} = $self->gap_penalty();
	}

	# Score
	for(my $i = 1 ; $i <= $max_i; $i++){
		my $ci = $merger{$i-1};
		for(my $j = 1; $j <= $max_j; $j++){
			my $cj = $list[$j-1];
			# Scoring
			my $diag_score = $score_mat{$i-1}{$j-1} + $self->Sij($ci,$cj);
			my $up_score = $score_mat{$i-1}{$j} + $self->gap_penalty();
			my $left_score = $score_mat{$i}{$j-1} + $self->gap_penalty();

			if($diag_score >= $up_score){
				if($diag_score >= $left_score){
					$score_mat{$i}{$j} = $diag_score;
					$point_mat{$i}{$j} = 'D';
				}else{
					$score_mat{$i}{$j} = $left_score;
					$point_mat{$i}{$j} = 'L';
				}
			}else{
				if($up_score >= $left_score){
					$score_mat{$i}{$j} = $up_score;
					$point_mat{$i}{$j} = 'U';
				}else{
					$score_mat{$i}{$j} = $left_score;
					$point_mat{$i}{$j} = 'L';
				}
			}
		}
	}

	$self->print2DArray('score_mat', \%score_mat);
	$self->print2DArray('point_mat', \%point_mat);


	# Calculate merger
	my @new_row_set;
	my $i = $max_i + 0;
	my $j = $max_j + 0;
	while($i != 0 || $j != 0){
		my $dir = $point_mat{$i}{$j};
		my @new_row;
		if($dir eq 'D'){
			push(@new_row, @{$merger{$i-1}}, $list[$j-1]);
			$i--;
			$j--;
		}elsif($dir eq 'L'){
			push(@new_row, split(//, '-' x ($self->number_of_aligned_lists())));
			push(@new_row, $list[$j-1]);
			$j--;
		}elsif($dir eq 'U'){
			push(@new_row, @{$merger{$i-1}}, '-');
			$i--;
		}
		if($self->verbose()){
			print join("\t", $i, $j, $dir, @new_row),"\n";
		}
		push(@new_row_set,\@new_row);
	}

	my %new_merger;
	for(my $i = 0; $i < scalar(@new_row_set); $i++){
		$new_merger{$i} = $new_row_set[scalar(@new_row_set) - $i - 1];
	}
	$self->merger(\%new_merger);
}

sub merged_array{
	my ($self) = @_;
	my %m = %{$self->merger()};
	my @result;
	foreach(sort{$a<=>$b} keys(%m)){
		push(@result, $m{$_});
	}
	return @result;
}


sub print2DArray{
	my($self,$name, $ref) = @_;
	if($self->verbose && defined $ref){
		print '*' x 32,"\n";
		print $name,"\n";
		if(ref $ref eq 'ARRAY'){	
			foreach(@{$ref}){
				print join("\t",@{$_}),"\n";
			}
		}elsif(ref $ref eq 'HASH'){
			my %h = %{$ref};
			foreach my $a(sort(keys(%h))){
				if(ref $h{$a} eq 'ARRAY'){
					print join("", map { sprintf "%-4s",$_ } @{$h{$a}});
				}else{
					foreach my $b(sort(keys($h{$a}))){
						if(defined($h{$a}{$b})){
							printf "%5s", $h{$a}{$b};
						}
					}
				}
				print "\n";
			}
		}else{
			die 'Unsupported';
		}
		print '*' x 32,"\n";
	}
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::NW_MSA

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
