package CPT::Bio::DataSource;
use Moose::Role;
use strict;
use warnings;
use autodie;

requires 'getSeqIO';


sub test {

}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::DataSource

=head1 VERSION

version 1.99.4

=head2 test

	$ds->test()

empty method for now

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
