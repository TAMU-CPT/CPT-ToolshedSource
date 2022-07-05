package CPT::External::LipoP;
no warnings;
use Moose;
use File::Temp qw(tempfile);
use IPC::Run qw(run);

has 'sequence' => ( is => 'rw', isa => 'Str' );
has 'response' => ( is => 'rw', isa => 'Str' );
has 'cleavage' => ( is => 'rw', isa => 'ArrayRef' );
has 'tmpfile' => (is => 'rw', isa => 'Any');

sub create_fasta_file {
	my ( $self, $seq ) = @_;
	my ( $fh, $filename ) = tempfile( "cpt.lipop.XXXXXXX", UNLINK => 1 );

	#printf $fh ">%s\n%s\n", 'seq', $seq;
	printf $fh "%s\n", $seq;
	close($fh);
	return $filename;
}

sub parse_text {
	my ($self) = @_;

	foreach my $line ( split( /\n/, $self->response() ) ) {
		if ( $line =~ /#.*cleavage=(\d+)-(\d+)/ ) {
			$self->cleavage( [ $1, $2 ] );
		}
	}
	#	# seq SpII score=17.8897 margin=13.48964 cleavage=19-20 Pos+2=K
	#	# Cut-off=-3
	#	seq	LipoP1.0:Best	SpII	1	1	17.8897
	#	seq	LipoP1.0:Margin	SpII	1	1	13.48964
	#	seq	LipoP1.0:Class	SpI	1	1	4.40006
	#	seq	LipoP1.0:Class	CYT	1	1	-0.200913
	#	seq	LipoP1.0:Signal	CleavII	19	20	17.8897	# LVVSA|CKSPP Pos+2=K
	#	seq	LipoP1.0:Signal	CleavI	28	29	4.03409	# PPVQS|QRPEP
	#	seq	LipoP1.0:Signal	CleavI	21	22	2.04071	# VSACK|SPPPV
	#	seq	LipoP1.0:Signal	CleavI	27	28	-2.07502	# PPPVQ|SQRPE
	#	seq	LipoP1.0:Signal	CleavI	19	20	-2.6907	# LVVSA|CKSPP
	#	seq	LipoP1.0:Signal	CleavI	22	23	-2.87659	# SACKS|PPPVQ
}

sub analyze {
	my ( $self, $seq ) = @_;
	$self->sequence($seq);
	$self->tmpfile($self->create_fasta_file($seq));
	my @cmd = ( 'LipoP', $self->tmpfile(), '-workdir', '/tmp/nonexistant/', '-wwwdir', '/tmp/nonexistant' );
	my ( $in, $out, $err );
	run \@cmd, \$in, \$out, \$err;
	if ($err) { print "Error: $err\n"; }
	$self->response($out);
	$self->parse_text();
	unlink($self->tmpfile());
}

sub cleanup {
	my ($self) = @_;
	return;
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::External::LipoP

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
