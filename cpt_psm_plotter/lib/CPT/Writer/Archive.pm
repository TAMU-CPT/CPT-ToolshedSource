package CPT::Writer::Archive;
no warnings;
use Moose;
use Archive::Any::Create;
use File::Copy qw/move/;
with 'CPT::Writer';

has format => (
	is	    => 'ro',
	isa 	=> 'Str',
	default => sub {
		'tar.gz',
	},
);

sub process {
	my ($self) = @_;
	# Should be a Archive::Any::Create object
	if(ref $self->data() ne 'Archive::Any::Create'){
		warn 'Tool author sent non Archive::Any::Create data to the writer';
	}else{
		$self->processed_data( $self->data() );
		$self->processing_complete(1);
	}
}

sub write {
	my ($self) = @_;
	if ( $self->processing_complete ) {
		# Force the extension to that of the specified format
		$self->OutputFilesClass->extension( $self->format() );
		# Get a filename
		my $next_output_file = $self->OutputFilesClass->get_next_file();
		# And get another filename with extension tacked on so we KNOW it'll behave correctly.
		my $next_output_file_with_extension = $self->OutputFilesClass->get_next_file() . '.' . $self->format();
		# Store the name of the file we used
		push(@{$self->used_filenames()}, $next_output_file);
		# Write data out
		$self->processed_data->write_file($next_output_file_with_extension);
		# If it has been written somewhere other than where we want,
		# then we need to move it.
		if($next_output_file ne $next_output_file_with_extension){
			move($next_output_file_with_extension, $next_output_file);
		}
	}
	else {
		warn
"Write called but processing was not marked as complete. Not writing";
	}

}

sub suffix {
	return 'csv';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Archive

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
