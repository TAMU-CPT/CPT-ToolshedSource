package CPT::Chado::GMOD_Conf;
use Moose;

has 'database_identifier' => ( is => 'rw', isa => 'Str' );
has 'gmod_root' => ( is => 'rw', isa => 'Str', default => '/usr/share/gmod/' );
has 'database'  => ( is => 'rw', isa => 'Str' );
has 'username'  => ( is => 'rw', isa => 'Str' );
has 'password'  => ( is => 'rw', isa => 'Str' );
has 'host' => ( is => 'rw', isa => 'Str', default => 'localhost' );
has 'port' => ( is => 'rw', isa => 'Int', default => 5432 );

sub load_config {
	my ( $self, $identifier ) = @_;
	open( my $db_info, '<',
		$self->gmod_root() . "conf/${identifier}.conf" );
	while (<$db_info>) {
		chomp $_;
		if ( $_ =~ /DBUSER=/ ) {
			$self->username( substr( $_, 7 ) );
		}
		elsif ( $_ =~ /DBPASS=/ ) {
			$self->password( substr( $_, 7 ) );
		}
		elsif ( $_ =~ /DBNAME=/ ) {
			$self->database( substr( $_, 7 ) );
		}
	}
	close($db_info);
}

sub get_connector {
	my ( $self, $identifier ) = @_;
	$self->load_config($identifier);
	use DBI;
	my $dbh = DBI->connect(
		sprintf(
			"dbi:Pg:dbname=%s;host=%s;port=%s;",
			$self->database(), $self->host(), $self->port()
		),
		$self->username(),
		$self->password()
	);
	return $dbh;
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Chado::GMOD_Conf

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
