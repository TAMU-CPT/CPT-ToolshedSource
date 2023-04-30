package CPT::Logger;
use Moose;
use strict;
use warnings;
use autodie;

# This will eventually be merged into CPT proper.

has 'outfile'       => ( is => 'ro', isa => 'Str' );
has 'appid'         => ( is => 'ro', isa => 'Str' );
has 'outfilehandle' => ( is => 'ro', isa => 'FileHandle' );

my $fh;

sub new {
	my ( $class, %options ) = @_;
	my $self = {%options};
	bless( $self, $class );
	if ( $self->{'outfile'} ) {
		open( $fh, '>>', $self->{'outfile'} );
	}
	return $self;
}

sub log {
	my ( $self, $message ) = @_;
	my @t = localtime;
	$t[5] += 1900;
	$t[4]++;
	my $time = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
	  @t[ 5, 4, 3, 2, 1, 0 ];
	print $fh "[$time] $message\n";
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Logger

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
