package CPT::Plot::ArtemisColours;
use Moose;
use strict;
use warnings;
use Carp;

has format => (
	is      => 'rw',
	isa     => 'Str',
	default => sub {
		'svg/rgb'
	},
);

my %artemis_colours = (
	0  => [ 255, 255, 255 ],
	1  => [ 100, 100, 100 ],
	2  => [ 255, 0,   0 ],
	3  => [ 0,   255, 0 ],
	4  => [ 0,   0,   255 ],
	5  => [ 0,   255, 255 ],
	6  => [ 255, 0,   255 ],
	7  => [ 255, 255, 0 ],
	8  => [ 152, 251, 152 ],
	9  => [ 135, 206, 250 ],
	10 => [ 255, 165, 0 ],
	11 => [ 200, 150, 100 ],
	12 => [ 255, 200, 200 ],
	13 => [ 170, 170, 170 ],
	14 => [ 0,   0,   0 ],
	15 => [ 255, 63,  63 ],
	16 => [ 255, 127, 127 ],
	17 => [ 255, 191, 191 ],
);

sub getAvailableFormats {
	my ($self) = @_;
	return [ 'svg/rgb', 'artemis' ];
}

sub getColour {
	my ( $self, $string ) = @_;
	if ($string) {
		my @rgb;
		if ( $string =~ qr/^\s*(\d+)\s*$/ ) {
			@rgb = @{ $artemis_colours{$1} };
		}
		elsif ( $string =~ qr/^\s*(\d+)\s+(\d+)\s+(\d+)\s*$/ ) {
			@rgb = ( $1, $2, $3 );
		}
		else {
			confess "Bad Colour Specfication [$string]";
			return;
		}

		# return $colour_result;
		my $format = $self->format();
		if ( $format eq 'svg/rgb' ) {
			return 'rgb(' . join( ',', @rgb ) . ')';
		}
		elsif ( $format eq 'artemis' ) {
			return join( ' ', @rgb );
		}
		else {
			carp "Bad format specified, or format not added to spec list [$format]";
		}
	}
	else {
		return;
	}
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Plot::ArtemisColours

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
