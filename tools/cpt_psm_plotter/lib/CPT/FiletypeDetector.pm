package CPT::FiletypeDetector;
use Moose;
use strict;
use warnings;
use Data::Dumper;
use autodie;

# ABSTRACT: an incredibly basic filetype detection library for genomic data


sub head {
	my ($self, $filename) = @_;
	# We're only going to focus on detecting a few types
	open( my $file, '<', $filename );
	my @lines;
	my $c = 0;
	while (<$file>) {
		# Read ten lines
		if ( $c++ < 10 ) {
			chomp $_;
			push( @lines, $_ );
		}
		# Then exit
		else {
			last;
		}
	}
	close($file);
	return @lines;
}

sub detect {
	my ( $self, $filename ) = @_;

	my @lines = $self->head($filename);

	use CPT::Filetype::gff3;
	use CPT::Filetype::gbk;
	use CPT::Filetype::embl;
	use CPT::Filetype::fasta;

	my @scorers = (
		CPT::Filetype::gff3->new(lines => \@lines, file => $filename),
		CPT::Filetype::gbk->new(lines => \@lines, file => $filename),
		CPT::Filetype::embl->new(lines => \@lines, file => $filename),
		CPT::Filetype::fasta->new(lines => \@lines, file => $filename),
	);

	my $best_score = 0;
	my $best_name = "";
	foreach(@scorers){
		my $score = $_->score();
		# "1 indicating ... to the exclusion [of others]
		if($score == 1){
			return $_->name();
		}
		
		# Otherwise check if better
		if($score > $best_score){
			$best_name = $_->name();
		}
	}

	return $best_name;

       #	if(defined $string){
       #		return 'fasta'    if( $string =~ /\.(fasta|fast|seq|fa|fsa|nt|aa)$/i);
       #		return 'genbank'  if( $string =~ /\.(gb|gbank|genbank|gbk)$/i);
       #		return 'scf'	  if( $string =~ /\.scf$/i);
       #		return 'pir'	  if( $string =~ /\.pir$/i);
       #		return 'embl'	  if( $string =~ /\.(embl|ebl|emb|dat)$/i);
       #		return 'raw'	  if( $string =~ /\.(txt)$/i);
       #		return 'gcg'	  if( $string =~ /\.gcg$/i);
       #		return 'ace'	  if( $string =~ /\.ace$/i);
       #		return 'bsml'	  if( $string =~ /\.(bsm|bsml)$/i);
       #		return 'swiss'    if( $string =~ /\.(swiss|sp)$/i);
       #		return 'phd'	  if( $string =~ /\.(phd|phred)$/i);
       #		return 'gff'	  if( $string =~ /\.(gff|gff3)$/i);
       #		return 'blastxml' if( $string =~ /\.(xml)$/i);
       #		die "File type detection failure";
       #	}
       #	else{
       #		die "File type detection failure";
       #	}

}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::FiletypeDetector - an incredibly basic filetype detection library for genomic data

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
