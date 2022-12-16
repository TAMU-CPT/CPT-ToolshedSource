package CPT::External::TMHMM;
no warnings;
use Moose;
use File::Temp qw(tempfile);
use IPC::Run qw(run);
use File::Temp qw(tempdir);
use File::Copy qw(move);

has 'sequence' => ( is => 'rw', isa => 'Str' );
has 'response' => ( is => 'rw', isa => 'Str' );

has 'num_predicted'       => ( is => 'rw', isa => 'Int' );
has 'predicted_locations' => ( is => 'rw', isa => 'ArrayRef' );
has 'prob_n_in'           => ( is => 'rw', isa => 'Str' );
has 'hash'                => ( is => 'rw', isa => 'Str' );
has 'picture_location'    => ( is => 'rw', isa => 'Str' );

my ( $fh, $filename, $image );

sub create_fasta_file {
	my ( $self, $seq ) = @_;
	( $fh, $filename ) = tempfile( "cpt.tmhmm.XXXXXXX", UNLINK => 1 );

	#printf $fh ">%s\n%s\n", 'seq', $seq;
	printf $fh "%s\n", $seq;
	return $filename;
}

sub parse_text {
	my ($self) = @_;
	unless ( $self->predicted_locations() ) {
		$self->predicted_locations( [] );
	}
	unless ( $self->num_predicted() ) {
		$self->num_predicted(0);
	}
	foreach my $line ( split( /\n/, $self->response() ) ) {
		if ( $line =~ /Number of predicted TMHs:\s*(\d+)/ ) {
			$self->num_predicted($1);
		}
		elsif ( $line =~ /Total prob of N-in:\s*([0-9.]*)/ ) {
			$self->prob_n_in($1);
		}
		elsif ( $line =~ /TMHMM2.0\s*TMhelix\s*([0-9]+)\s*([0-9]+)/ ) {

			#$self->num_predicted($self->num_predicted()+1);
			push( @{ $self->predicted_locations() }, [ $1, $2 ] );
		}
	}

	#	# seq Length: 145
	#	# seq Number of predicted TMHs:  1
	#	# seq Exp number of AAs in TMHs: 20.91302
	#	# seq Exp number, first 60 AAs:  20.91265
	#	# seq Total prob of N-in:        0.04659
	#	# seq POSSIBLE N-term signal sequence
	#	seq	TMHMM2.0	outside	     1     3
	#	seq	TMHMM2.0	TMhelix	     4    23
	#	seq	TMHMM2.0	inside	    24   145
}

sub analyze {
	my ( $self, $seq ) = @_;

	# Set our hash
	require Digest::MD5;
	$self->hash( Digest::MD5::md5_hex($seq) );

	# Set our sequence
	$self->sequence($seq);

	# Tmp dir to run in
	my $dir = tempdir( CLEANUP => 1 );
	my $tmpfile = $self->create_fasta_file($seq);

	# Plot and use specified workdir
	my @cmd = ( 'tmhmm.pl', '-plot', '-workdir', $dir, '<', $tmpfile );

	# Run the command
	my ( $in, $out, $err );
	run \@cmd, \$in, \$out, \$err;

	# If error,we error
	if ($err) {

		# print STDERR "Error: $err\n";
		# Kinda a crappy way to handle this...
		$self->response($err);
		return 0;
	}
	{

		# Move the created plot to a known location
		my @tmhmm_files = glob("$dir/*/*.png");

		# There's really only one png but this is just as easy to write
		for my $png (@tmhmm_files) {
			$image = sprintf( "/tmp/cpt.ext.tmhmm.%s.png", $self->hash() );
			move( $png, $image );
		}

		# Module to remove the temporary dir so we clean up after
		# ourselves quickly, since this programme seems to open a LARGE
		# number of file handles.
		require File::Path;
		File::Path::remove_tree($dir);

		# set response and parse it, then return OK.
		$self->response($out);
		$self->parse_text();
		return 1;
	}
}

sub cleanup {
	if ( defined($fh) ) {
		close($fh);
		unlink($filename);
		if ( -e $image ) {
			unlink($image);
		}
	}
}

END {
	if ( defined($fh) ) {
		close($fh);
		unlink($filename);
		if ( -e $image ) {
			unlink($image);
		}
	}
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::External::TMHMM

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
