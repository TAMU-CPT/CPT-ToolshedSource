package CPT::Bio::DataSource::GFF3;
no warnings;
use Moose;
with 'CPT::Bio::DataSource';


sub getSeqIO {
	die 'unimplemented';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::DataSource::GFF3

=head1 VERSION

version 1.99.4

=head2 getSeqIO

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
