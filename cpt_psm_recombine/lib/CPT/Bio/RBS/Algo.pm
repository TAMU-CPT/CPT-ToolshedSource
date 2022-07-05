package CPT::Bio::RBS::Algo;
use Moose::Role;
use strict;
use warnings;
use autodie;

# Function to predict RBSs in a given sequence
requires 'predict';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::RBS::Algo

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
