package CPT::Writer;
use Moose::Role;
use strict;
use warnings;
use autodie;

requires 'process';
requires 'suffix';

# One or the other of these will be set. *ought* to be in accordance w/ galaxy_override
has 'OutputFilesClass' => ( is => 'rw' );

# This parameter specifies that we should behave according to galaxy_override spec.
has 'galaxy_override'     => ( is => 'rw', isa => 'Bool' );
has 'title'               => ( is => 'rw', isa => 'Str' );
has 'author'              => ( is => 'rw', isa => 'Str' );
has 'data'                => ( is => 'rw' );
has 'processed_data'      => ( is => 'rw' );
has 'processing_complete' => ( is => 'rw', isa => 'Bool' );
# What file names were generated during the writing process
has 'used_filenames' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] });
# An optional, hinted at name. Otherwise we'll generate one.
has 'name' => ( is => 'rw', isa => 'Str' );

sub write {
	my ($self) = @_;
	if ( $self->processing_complete ) {
		$self->OutputFilesClass->extension( $self->suffix() );
		my $next_output_file = $self->OutputFilesClass->get_next_file();
		# Store the name of the file we used
		push(@{$self->used_filenames()}, $next_output_file);
		# Write data out
		open(my $outfile, '>', $next_output_file );
		print $outfile $self->processed_data;   # given that processed_data is a string...
		close($outfile);
	}
	else {
		warn "Write called but processing was not marked as complete. Not writing";
	}
}

sub get_name {
	my ($self) = @_;
	#return $self->OutputFilesClass->get_next_file();
	return $self->OutputFilesClass->_get_filename();
}

sub process_data {
	my ($self) = @_;
	if (!defined $self->data ) {
		#confess "No data to process.";
	}
	$self->process();
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
