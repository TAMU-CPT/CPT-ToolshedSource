package CPT::Filetype;
use Moose::Role;
use strict;
use warnings;
use autodie;

has lines => ( is => 'rw', isa => 'ArrayRef');
# Also have file location if we need to open a filehandle on it to further
# check.
has file => ( is => 'rw', isa => 'Str');


requires 'score';
requires 'name';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Filetype

=head1 VERSION

version 1.99.4

=head1 score

Score should be a method that returns a number between 0 and 1 describing the
probability that it is this format, with 1 indicating that it truly is this
file to the exclusion of every other type.

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
