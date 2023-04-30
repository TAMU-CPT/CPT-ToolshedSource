package CPT::Galaxy;
use Moose;
use strict;
use warnings;
use Data::Dumper;
use autodie;


sub gen {
	my ( $self, %p ) = @_;
	my $parameterCollection = $p{full_options};
	my @opt_spec            = @{ $parameterCollection->params() };    # This feels bad?
	my %defaults            = @{ $p{defaults} };
	my @outputs             = @{ $p{outputs} };
	my @tests;
	if(defined $p{tests} && ref $p{tests} eq 'ARRAY'){
	    @tests = @{ $p{tests} };
	}

	my $optional_output_file = $p{_output_file};

	#my @registered_outputs = @{ $outputs{'registered'} };
	my $appid   = $p{appid};
	my $appname = $p{appname};
	my $appdesc = $p{appdesc};
	my $appvers = $p{appvers};

	# Set up the XML Writer
	require XML::Writer;
	my $xml_writer;
	if($optional_output_file){
		$xml_writer = XML::Writer->new(OUTPUT => $optional_output_file);
	}else{
		$xml_writer = XML::Writer->new();
	}

	# Set up the tool element
	$xml_writer->startTag(
		'tool',
		id      => $appid,
		name    => $appname,
		version => $appvers,
	);

	# Add all of our sections, passing a single xml_writer around.
	$self->description_section($xml_writer,$appdesc);
	$self->version_section($xml_writer);
	$self->stdio_section($xml_writer);

	$self->command_section($xml_writer,\@opt_spec);
	$self->input_section($xml_writer,\@opt_spec);
	$self->output_section($xml_writer,\@opt_spec);

	$self->help_section($xml_writer);

	$self->test_section($xml_writer, @tests);

	$xml_writer->endTag('tool');
	$xml_writer->end();
	# End of tool xml conf
	
	# if OOF was set to 'self', that means it's stored internally, so we should return
	if(defined $optional_output_file && $optional_output_file eq 'self'){
		return $xml_writer->to_string;
	}
}

sub test_section {
	my ($self, $xml_writer, @test_cases) = @_;
	$xml_writer->startTag('tests');
	foreach my $test(@test_cases){
		my %test_details = %{$test};
		$xml_writer->startTag('test');
		# Each test case has: name, params, outputs

		# Params will be as they're specified on the command line, so they /should/ be okay to use in galaxy code.
		my %params = %{$test_details{'params'}};
		foreach(sort(keys(%params))){
			# As written, will not handle multiply valued attributes
			$xml_writer->startTag('param',
				name  => $_,
				value => $params{$_},
			);
			$xml_writer->endTag();
		}
		# outputs
		my %outputs = %{$test_details{'outputs'}};
		foreach(sort(keys(%outputs))){
			# As written, will not handle multiple outputs well
			# This bit of code because for every output there's a
			# name you expect on the command line, and a file you
			# want to compare against (galaxy mucks about with
			# names so we don't have to worry about it. However,
			# from the command line, we have to know the name of
			# the output file we're going to produce so we can
			# compare it against another copy of this file. It's
			# less than ideal, but there's not much we can do.
			my @output_cmp = @{$outputs{$_}};
			$xml_writer->startTag('output',
				name => $_,
				file => $output_cmp[1],
			);
			$xml_writer->endTag();
		}
		$xml_writer->endTag();
	}
	$xml_writer->endTag();
}

sub description_section{
	my ($self, $xml_writer, $appdesc) = @_;
	$xml_writer->startTag('description');
	$xml_writer->characters(sprintf('%s',$appdesc));
	$xml_writer->endTag('description');
}

sub version_section{
	my ($self, $xml_writer) = @_;
	$xml_writer->startTag('version_command');
	$xml_writer->characters("perl $0 --version");
	$xml_writer->endTag('version_command');
}
sub stdio_section{
	my ($self, $xml_writer) = @_;
	$xml_writer->startTag('stdio');
	$xml_writer->startTag(
		'exit_code',
		range => "1:",
		level => "fatal",
	);
	$xml_writer->endTag('exit_code');
	$xml_writer->endTag('stdio');
}
sub command_section{
	###################
	# COMMAND SECTION #
	###################
	my ($self, $xml_writer,$opt_spec_ref) = @_;
	my @opt_spec = @{$opt_spec_ref};
	$xml_writer->startTag(
		'command',
		interpreter      => 'perl',
	);
	my $command_string = join("\n", $0, '--galaxy','--outfile_supporting $__new_file_path__','');
	foreach (@opt_spec) {
		if(
		    # not galaxy specific and we are not instructed to hide
		    !$_->_galaxy_specific() && $_->_show_in_galaxy()
		    ||
		    # is galaxy specific and is hidden
		    $_->_galaxy_specific() && $_->hidden() && $_->_show_in_galaxy() 
		){
		#if(!$_->hidden() || ){
			my $command_addition = $_->galaxy_command();
			if($command_addition){
				$command_string .= $command_addition . "\n";
			}
		}
	}
	$xml_writer->characters($command_string);
	$xml_writer->endTag('command');
}
sub input_section{
	my ($self, $xml_writer,$opt_spec_ref) = @_;
	my @opt_spec = @{$opt_spec_ref};
	#################
	# INPUT SECTION #
	#################
	$xml_writer->startTag('inputs');
	foreach (@opt_spec) {
		if(
		    # not galaxy specific and we are not instructed to hide
			!$_->hidden() && !$_->_galaxy_specific() && $_->_show_in_galaxy()
		){
			$_->galaxy_input($xml_writer);
		}
	}
	$xml_writer->endTag('inputs');
}
sub output_section{
	my ($self, $xml_writer,$opt_spec_ref) = @_;
	my @opt_spec = @{$opt_spec_ref};
	##################
	# OUTPUT SECTION #
	##################
	$xml_writer->startTag('outputs');
	foreach (@opt_spec) {
		if(
		    # not galaxy specific and we are not instructed to hide
		    !$_->_galaxy_specific() && $_->_show_in_galaxy()
		){
			$_->galaxy_output($xml_writer);
		}
	}
	$xml_writer->endTag('outputs');
}
sub help_section{
	my ($self, $xml_writer) = @_;
	################
	# HELP SECTION #
	################

	$xml_writer->startTag('help');
	# Here we incur some dependencies. D:
	use IPC::Run3;
	my ($in,$out,$err);
	use File::Temp;
	my $tempfile = File::Temp->new(
		TEMPLATE => 'libcpt.galaxy.tempXXXXX',
		DIR      => '/tmp/',
		UNLINK   => 1,
		SUFFIX   => '.html'
	);

	use File::Which;
	my $pod2md = which("pod2markdown");
	if(! defined($pod2md)){
		print STDERR "pod2markdown not available. Install Pod::Markdown";
	}else{
		my @command = ('pod2markdown',$0,$tempfile);
		run3 \@command, \$in, \$out, \$err;
		# Pandoc
		my $pandoc = which("pandoc");
		if(! defined($pandoc)){
			print STDERR "Pandoc not available, cannot convert to RST";
		}else{
			@command = ("pandoc",'-f','markdown','-t','rst', $tempfile);
			run3 \@command, \$in, \$out, \$err;
			if(-e $tempfile){
			    unlink($tempfile);
			}
			$xml_writer->characters($out);
		}
	}
	$xml_writer->endTag('help');
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Galaxy

=head1 VERSION

version 1.99.4

=head2 gen

	require CPT::Galaxy;
	my $galaxy_xml_generator = CPT::Galaxy->new();
	$galaxy_xml_generator->gen(
		full_options => \@options_specification,
		appdesc      => $self->{'appdesc'},
		appid        => $self->{'appid'},
		appname      => $self->{'appname'},
		defaults     => $passed_opts{'defaults'},
		outputs      => $passed_opts{'outputs'},
	);

Generates a galaxy XML file (using XML::Writer) from the options_specification object, which is an array of 
['file|f=s', "blah", {some_req => 'some_val'] and CPT::Parameter::* objects. For simplicity, the first type 
is currently DEPRECATED

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
