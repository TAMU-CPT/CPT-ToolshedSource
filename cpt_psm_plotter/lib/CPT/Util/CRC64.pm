package CPT::Util::CRC64;

# This was taken from Bio::GMOD::Bulkfiles::SWISS_CRC64

use Moose;
use strict;
use warnings;
use autodie;


has 'POLY64REVh' => ( is => 'ro', isa => 'Any', default      => 0xd8000000 );
has 'CRCTableh'  => ( is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'CRCTablel'  => ( is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'initialized' => ( is => 'rw', isa => 'Bool', default     => 0 );
has 'size'       => ( is => 'rw', isa => 'Int' );
has 'crcl' => (is => 'rw', isa => 'Any', default => 0);
has 'crch' => (is => 'rw', isa => 'Any', default => 0);

sub add {
	my ($self, $sequence) = @_;
	my $crcl = $self->crcl();
	my $crch = $self->crch();
	my $size = $self->size();
	my @CRCTableh = @{$self->CRCTableh()};
	my @CRCTablel = @{$self->CRCTablel()};

	foreach (split //, $sequence){
		my $shr = ($crch & 0xFF) << 24;
		my $temp1h = $crch >> 8;
		my $temp1l = ($crcl >> 8) | $shr;
		my $tableindex = ($crcl ^ (unpack "C", $_)) & 0xFF;
		$crch = $temp1h ^ $CRCTableh[$tableindex];
		$crcl = $temp1l ^ $CRCTablel[$tableindex];
		$size++;
	}
	$self->crcl($crcl);
	$self->crch($crch);
	$self->size($size);
}

sub hexsum {
	my ($self) = @_;
	my $crcl = $self->crcl();
	my $crch = $self->crch();
	return sprintf("%08X%08X", $crch, $crcl);
}

sub init {
	my ($self) = @_;
	$self->crcl(0);
	$self->crch(0);
	$self->size(0);
	my @h;
	my @l;
	my $POLY64REVh = $self->POLY64REVh();
	if(! $self->initialized() ){
		$self->initialized(1);
		for (my $i=0; $i<256; $i++) {
			my $partl = $i;
			my $parth = 0;
			for (my $j=0; $j<8; $j++) {
				my $rflag = $partl & 1;
				$partl >>= 1;
				$partl |= (1 << 31) if $parth & 1;
				$parth >>= 1;
				$parth ^= $POLY64REVh if $rflag;
			}
			$h[$i] = $parth;
			$l[$i] = $partl;
		}
		$self->CRCTableh(\@h);
		$self->CRCTablel(\@l);
	}
}

sub crc64 {	
	my ($self, $sequence) = @_;
	$self->init();
	$self->add($sequence);
	return $self->hexsum();
}

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Util::CRC64

=head1 VERSION

version 1.99.4

=head1 CRC64 perl module documentation

=head2 NAME

CRC64 - Calculate the cyclic redundancy check.

=head2 SYNOPSIS

   use CPT::Util::CRC64;

   my $crc = CPT::Util::CRC64->new();
   $crc = $crc->add("IHATEMATH");
   #returns the string "E3DCADD69B01ADD1"

=head2 DESCRIPTION

SWISS-PROT + TREMBL use a 64-bit Cyclic Redundancy Check for the
amino acid sequences.

The algorithm to compute the CRC is described in the ISO 3309
standard.  The generator polynomial is x64 + x4 + x3 + x + 1.
Reference: W. H. Press, S. A. Teukolsky, W. T. Vetterling, and B. P.
Flannery, "Numerical recipes in C", 2nd ed., Cambridge University 
Press. Pages 896ff.

=head2 Functions

=over

=item crc64 string

Calculate the CRC64 (cyclic redundancy checksum) for B<string>.

In array context, returns two integers equal to the higher and lower
32 bits of the CRC64. In scalar context, returns a 16-character string
containing the CRC64 in hexadecimal format.

=back

=head1 AUTHOR

Alexandre Gattiker, gattiker@isb-sib.ch

Eric Rasche <rasche.eric@yandex.ru> (reworte for CPT framework)

=head1 ACKNOWLEDGEMENTS

Based on SPcrc, a C implementation by Christian Iseli, available at 
ftp://ftp.ebi.ac.uk/pub/software/swissprot/Swissknife/old/SPcrc.tar.gz

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
