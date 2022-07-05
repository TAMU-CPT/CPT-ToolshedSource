package CPT::Plot::Class;
use Moose;
use Data::Dumper;

# ABSTRACT: Class of objects for use in a genome map
#
has 'objects' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

# Should this class be used in calculation of partitions
has 'included' => ( is => 'rw', isa => 'Bool' );

has 'key'    => ( is => 'rw', isa => 'Str' );
has 'color'  => ( is => 'rw', isa => 'Str' );
has 'border' => ( is => 'rw', isa => 'Str' );
has 'plot'   => ( is => 'rw', isa => 'Bool' );

sub addObject {
	my ( $self, $object ) = @_;
	push( @{ $self->objects() }, $object );
}

sub getItemList {
	my ($self) = @_;
	my @items;
	foreach ( @{ $self->objects() } ) {
		push( @items, $_->getLocations() );
	}
	return \@items;
}

sub getObjects {
	my ($self) = @_;
	return $self->objects();
}

sub getMemberCount {
	my ($self) = @_;
	return scalar @{ $self->objects() };
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Plot::Class - Class of objects for use in a genome map

=head1 VERSION

version 1.96

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
