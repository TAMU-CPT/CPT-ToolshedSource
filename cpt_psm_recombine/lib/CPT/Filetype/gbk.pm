package CPT::Filetype::gbk;
no warnings;
use Moose;
with 'CPT::Filetype';

sub score {
	my ($self) = @_;
	my $first_line = ${$self->lines()}[0];
	return $first_line =~ '^LOCUS';
}

sub name {
	return 'genbank';
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Filetype::gbk

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
