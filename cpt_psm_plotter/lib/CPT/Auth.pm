package CPT::Auth;
use strict;
use warnings;
use autodie;
use Moose;

has DN => (
	is	    => 'rw',
	isa 	=> 'Str',
);


sub check_credentials {
	my ( $self, %params ) = @_;
	use Net::LDAPS;
	print STDERR "Connecting to LDAP\n";
	my $base = 'dc=tamu,dc=edu';
	my $ldap = Net::LDAPS->new('00-ldap-biobio.tamu.edu') or die "$@";
	my $mesg = $ldap->bind;    # an anonymous bind

	my $username = $params{'username'};
	my $password = $params{'password'};

	$mesg = $ldap->search(     # perform a search
		base   => $base,
		filter => "uid=$username",
	);
	my $max = $mesg->count;

	# Should we exit early?
	for ( my $i = 0 ; $i < $max ; $i++ ) {
		my $entry = $mesg->entry($i);
		$self->DN() = $entry->dn();
	}
	$mesg = $ldap->bind( $self->DN(), password => $password );
	if ( $mesg->error() eq 'Success' ) {
		return 1;

		#print "Succesfully logged you in";
	}
	else {
		return 0;

		#print "Error: ";
		#print $mesg->error();
	}
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Auth

=head1 VERSION

version 1.99.4

=head2 check_credentials

    $cptauth->check_credentials(username=>'J.doe',password=>$password);

return 1 or 0, based on success or failure, respectively.

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
