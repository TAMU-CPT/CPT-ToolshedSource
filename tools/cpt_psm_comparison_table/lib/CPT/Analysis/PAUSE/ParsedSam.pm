package CPT::Analysis::PAUSE::ParsedSam;

# ABSTRACT: Library for use in PAUSE analysis
use strict;
use warnings;
use Moose;
use SVG;

has 'coverage_density'               => ( is => 'rw', isa => 'ArrayRef' );
has 'read_starts'                    => ( is => 'rw', isa => 'ArrayRef' );
has 'read_ends'                      => ( is => 'rw', isa => 'ArrayRef' );
has 'max'                            => ( is => 'rw', isa => 'Int' );
has 'stats_start_max'                => ( is => 'rw', isa => 'Num' );
has 'stats_end_max'                  => ( is => 'rw', isa => 'Num' );
has 'stats_start_mean'               => ( is => 'rw', isa => 'Num' );
has 'stats_end_mean'                 => ( is => 'rw', isa => 'Num' );
has 'stats_start_standard_deviation' => ( is => 'rw', isa => 'Num' );
has 'stats_end_standard_deviation'   => ( is => 'rw', isa => 'Num' );

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Analysis::PAUSE::ParsedSam - Library for use in PAUSE analysis

=head1 VERSION

version 1.96

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
