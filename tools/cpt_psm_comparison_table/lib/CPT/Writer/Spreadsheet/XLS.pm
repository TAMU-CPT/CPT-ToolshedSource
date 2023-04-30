package CPT::Writer::Spreadsheet::XLS;
use Moose;
with 'CPT::Writer', 'CPT::Writer::Spreadsheet';
use Spreadsheet::WriteExcel;

sub process {
	my ($self) = @_;
	if ( $self->galaxy_override ) {
		die 'This class currently incompatible with Galaxy';
	}
	$self->OutputFilesClass->extension( $self->suffix() );
	my $next_output_file = $self->OutputFilesClass->get_next_file();
	my $workbook         = Spreadsheet::WriteExcel->new($next_output_file);

	my %data   = %{ $self->data };
	my @sheets = keys %data;
	foreach (@sheets) {
		my $current_worksheet = $workbook->add_worksheet($_);
		my $data_struc_ref    = $data{$_};

		#R,C,AR
		$current_worksheet->write_row( 0, 0,
			${$data_struc_ref}{'header'} );
		my $row = 1;
		foreach ( @{ ${$data_struc_ref}{'data'} } ) {
			$current_worksheet->write_row( $row, 0, $_ );
			$row++;
		}
	}
	$self->processed_data($workbook);
	$self->processing_complete(1);
}

sub write {
	my ($self) = @_;
	$self->processed_data()->close();
}

sub suffix {
	return 'xls';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Spreadsheet::XLS

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
