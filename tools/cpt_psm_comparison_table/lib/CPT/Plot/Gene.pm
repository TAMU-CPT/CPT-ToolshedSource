package CPT::Plot::Gene;
use Moose;
use strict;
use warnings;

# ABSTRACT: Stupid representation of a gene. Does not handle joined genes
has 'start'  => ( is => 'rw', isa => 'Int' );
has 'end'    => ( is => 'rw', isa => 'Int' );
has 'tag'    => ( is => 'rw', isa => 'Str' );
has 'label'  => ( is => 'rw', isa => 'Str' );
has 'strand' => ( is => 'rw', isa => 'Str' );
has 'color'  => ( is => 'rw', isa => 'Any' );

sub getLocations {
	my ($self) = @_;
	return [ $self->start(), $self->end() ];
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Plot::Gene - Stupid representation of a gene. Does not handle joined genes

=head1 VERSION

version 1.96

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
