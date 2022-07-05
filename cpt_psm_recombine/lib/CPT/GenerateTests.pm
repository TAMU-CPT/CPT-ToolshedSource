package CPT::GenerateTests;
use Moose;
use strict;
use warnings;
use autodie;


sub gen {
	my ( $self, @tests ) = @_;
	
	my $test_count = 0;

	# Header
	my @outtext = (
		'#!/usr/bin/env perl',
		'use strict;',
		'use warnings;',
		'use Test::More tests => 0;',
		'use IPC::Run3 qw(run3);',
		'',
		'my ( @base, @cmd, $in, $out, $err );',
		'',
		sprintf("%s = ('perl', '%s');", '@base', $0),
		'my %result_files = (',
	);
	my %test_names;
	# Loop across tests
	foreach my $test_ref(@tests){
		my %test = %{$test_ref};
		my %params = %{$test{params}};
		my $command_line = "";
		foreach(sort(keys(%params))){
			$command_line .= "--$_ $params{$_} ";
		}
		my %outputs = %{$test{outputs}};

		$test_names{$test{test_name}}++;
		if($test_names{$test{test_name}} > 1){
			printf STDERR "Duplicate test found: %s. This will cause fewer tests to be run than expected\n", $test{test_name};
		}
		push(@outtext, sprintf('  "%s" => {', $test{test_name}));
		push(@outtext, sprintf('    command_line => "%s",', $command_line));
		push(@outtext, '    outputs => {');

		foreach my $key(keys %outputs){
			push(@outtext, sprintf('      "%s" => ["%s", "%s"],', $key, @{$outputs{$key}}));
			# Add another test
			$test_count++;
			$test_count++;
		}
		push(@outtext, '    },');
		push(@outtext, '  },');
	};
	push(@outtext, ');');
	push(@outtext,'');

	push(@outtext, 'foreach ( keys(%result_files) ) {');
	push(@outtext, '  # run with the command line');
	push(@outtext, '  my @cmd1 = ( @base, split( / /, $result_files{$_}{command_line} ) );');
	push(@outtext, '  run3 \@cmd1, \$in, \$out, \$err;');
	push(@outtext, '  if($err){ print STDERR "Exec STDERR: $err"; }');
	push(@outtext, '  if($out){ print STDERR "Exec STDOUT $out"; }');
	push(@outtext, '  # and now compare files');
	push(@outtext, '  foreach my $file_cmp ( keys( %{$result_files{$_}{outputs}} ) ) {');
	push(@outtext, '    my ($gen, $static) = @{$result_files{$_}{outputs}{$file_cmp}};');
	push(@outtext, '    my @diff = ( "diff", $gen, $static );');
	push(@outtext, '    my ($in_g, $out_g, $err_g);');
	push(@outtext, '    run3 \@diff, \$in_g, \$out_g, \$err_g;');
	push(@outtext, '    if($err_g) { print STDERR "err_g $err_g\n"; }');
	push(@outtext, '    if($out_g) { print STDOUT "out_g $out_g\n"; }');
	push(@outtext, '    chomp $out_g;');
	push(@outtext, '    is( -e $gen, 1, "[$_] Output file must exist"); ');
	push(@outtext, '    is( length($out_g), 0, "[$_] Checking validity of output \'$file_cmp\'" );');
	push(@outtext, '    unlink $gen;');
	push(@outtext, '  }');
	push(@outtext, '}');

	# Update test counts
	$outtext[3] = "use Test::More tests => $test_count;";
	if($test_count == 0){
		return $self->gen_empty();
	}

	return join("\n", @outtext);
}

sub gen_empty {
	my ( $self ) = @_;
	
	my $test_count = 0;

	my @outtext = (
		'#!/usr/bin/env perl',
		'use strict;',
		'use warnings;',
		'use Test::More skip_all => "No tests defined for ' . $0 .'"',
	);
	return join("\n", @outtext);
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::GenerateTests

=head1 VERSION

version 1.99.4

=head2 gen

	require CPT::GenerateTests;
	my $tgen = CPT::GenerateTests->new();
	$tgen->gen(
		{
			test_name    => "Default",
			params => {
				'file' => 't/test-files/aa.gbk',
				'chromosome' => 'test',
				'color' => 'red',
				'intensity' => 'vvvvl',
			},
			outputs => {
				'result_name' => ['circos_k.txt', 'test-data/circos_k.txt'],
			}
		},
	);
	exit 1;

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
