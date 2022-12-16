package CPT::Writer::CSV_U;
no warnings;
use Moose;
with 'CPT::Writer';

sub process {
	my ($self) = @_;
	my %data = %{ $self->data };

	my @sheets = keys %data;
	my %complete_processed_data = map { $_ => "" } @sheets;
	foreach (@sheets) {
		my $tmp_data       = '';
		my $data_struc_ref = $data{$_};
		$tmp_data .=
		  join( ',',
			map { local $_ = $_; s/"/\\"/g; $_ }
			  @{ ${$data_struc_ref}{'header'} } )
		  . "\n";
		foreach ( @{ ${$data_struc_ref}{'data'} } ) {
			$tmp_data .= join(
				',',
				map {
					local $_ = $_;
					unless (defined $_) { $_ = "" }
					s/"/\\"/g;
					$_;
				  } @{$_}
			) . "\n";
		}
		$complete_processed_data{$_} = $tmp_data;
	}
	$self->processed_data( \%complete_processed_data );
	$self->processing_complete(1);
}

sub write {

       # Wanted to use child's write method here so I can output multiple files.
	my ($self) = @_;
	if ( $self->processing_complete ) {
		my %complete_processed_data = %{ $self->processed_data() };
		my @sheets                  = keys %complete_processed_data;

		# When this is initially called, the OutputFilesClass was given
		# a hint as to what files from this analysis should be called.
		# We'll borrow that and modify it each time before putting it
		# back at the end. Since this is the *ONLY* type that has
		# sub-reports, it feels O.K. to do it here.
		my $base_name = $self->OutputFilesClass->given_filename();
		unless ($base_name) { $base_name = ""; }
		foreach (@sheets) {
			# We update  the base filename to include our
			# particular Sheet name. As such the generate function
			# should start generating files with that as part of
			# the name
			$self->OutputFilesClass->given_filename( $base_name . '.' . $_ );
			$self->OutputFilesClass->extension('csv');
			my $next_output_file =
			  $self->OutputFilesClass->get_next_file();
		
			# Store the filename we used
			push(@{$self->used_filenames()}, $next_output_file);
			open( my $outfile, '>', $next_output_file );
			print $outfile $complete_processed_data{$_};
			close($outfile);
		}
		# Reset it back to default (probably unnecessary)
		$self->OutputFilesClass->given_filename($base_name);
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

CPT::Writer::CSV_U

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
