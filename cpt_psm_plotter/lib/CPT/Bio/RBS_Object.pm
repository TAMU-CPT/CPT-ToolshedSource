package CPT::Bio::RBS_Object;
use Moose;
use autodie;

has 'upstream'      => ( is => 'rw', isa => 'Str' );
has 'score' => (is => 'rw', isa => 'Int');
has 'rbs_seq' => (is => 'rw', isa => 'Str');
has 'separation' => (is => 'rw', isa => 'Int');

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::RBS_Object

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
