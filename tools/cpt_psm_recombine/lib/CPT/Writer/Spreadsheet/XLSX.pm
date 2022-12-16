package CPT::Writer::Spreadsheet::XLSX;
use Moose;
with 'CPT::Writer', 'CPT::Writer::Spreadsheet';
use Excel::Writer::XLSX;

#http://search.cpan.org/~jmcnamara/Excel-Writer-XLSX/lib/Excel/Writer/XLSX.pm#SPEED_AND_MEMORY_USAGE
#
#The effect of this is that Excel::Writer::XLSX is about 30% slower than Spreadsheet::WriteExcel and uses 5 times more memory.
#
#This memory usage can be reduced almost completely by using the Workbook set_optimization() method:
#
#    $workbook->set_optimization();
#
sub process {
	my ($self) = @_;
	if ( $self->galaxy_override ) {
		die 'This class currently incompatible with Galaxy';
	}
	my $workbook = Excel::Writer::XLSX->new(
		join( '.', $self->outfile(), $self->suffix() ) );
	$workbook->set_optimization();
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
	return 'xlsx';
}
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Writer::Spreadsheet::XLSX

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
