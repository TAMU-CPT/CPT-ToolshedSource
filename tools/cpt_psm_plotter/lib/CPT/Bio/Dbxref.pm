package CPT::Bio::Dbxref;
use Moose;
use autodie;
use YAML;
use File::ShareDir;
use File::Spec qw/catfile/;

has 'regex_map' => ( is => 'rw', isa => 'HashRef');
has 'initialized' => ( is => 'rw', isa => 'Int', default => 0);

sub init {
	my ($self) = @_;
	# Locate file
	my $data_dir = File::ShareDir::dist_dir('libCPT');
	my $dbxref_data = File::Spec->catfile($data_dir, 'dbxref.yaml');
	# Parse
	$self->regex_map(YAML::LoadFile($dbxref_data));
	$self->initialized(1);
}

sub get_prefix {
	my ($self, $dbxref) = @_;
	if(!$self->initialized()){
		$self->init();
	}

	my @hits;
	my %map = %{$self->regex_map()};
	# Search through regex database
	foreach my $db(keys(%map)){
		if(defined($map{$db}{local_id_syntax})){
			my $ref = $map{$db}{local_id_syntax};
			if(ref($ref) eq 'ARRAY'){
				foreach my $regi(@{$ref}){
					if($dbxref =~ /$regi/){
						push(@hits, $map{$db}{abbreviation});
					}
				}
			}
			if($dbxref =~ /$ref/){
				push(@hits, $map{$db}{abbreviation});
			}
		}
	}
	return @hits;
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Bio::Dbxref

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
