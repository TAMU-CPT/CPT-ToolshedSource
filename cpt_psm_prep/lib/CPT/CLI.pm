package CPT::CLI;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

CPT::CLI - a stub library to make Dist::Zilla happy

=head1 SYNOPSIS

	use CPT::CLI;

=head1 FUNCTIONAL INTERFACE

=head2 new

	my $libCPT = CPT::CLI->new();

=cut

sub new {
	my ( $class, %options ) = @_;
	my $self = bless( {}, $class );
	return $self;
}

1;
__END__

=head1 AUTHOR

Eric Rasche, <lt>rasche.eric@yandex.ru<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Eric Rasche

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
