package CPT::Parameter::Option::Generic;
use Moose;
with 'CPT::Parameter::Option';


sub getopt_format {
	return '=s';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter::Option::Generic

=head1 VERSION

version 1.99.4

=head2 getopt_format

Returns the format character for a given CPT::Parameter::* type

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
