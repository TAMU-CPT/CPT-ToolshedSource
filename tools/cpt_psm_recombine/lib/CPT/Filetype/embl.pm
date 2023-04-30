package CPT::Filetype::embl;
no warnings;
use Moose;
with 'CPT::Filetype';

sub score {
	my ($self) = @_;
	my $first_line = ${$self->lines()}[0];
	my @embl_identifiers = (
		'FT', 'FH', 'SQ', 'DE', 'AC', 'PA', 'SV', 'DT', 'KW',
		'OS', 'OC', 'OX', 'R ', ''  , 'DR', 'CC', 'CO', 'XX',
	);
	my %embl_id_map = map { $_ => 1 } @embl_identifiers;
	my $embl_score = 0;
	foreach(@{$self->lines()}){
		$embl_score++ if($embl_id_map{substr($_,0,2)});
	}
	return $embl_score/10;
}

sub name {
	return 'embl';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Filetype::embl

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
