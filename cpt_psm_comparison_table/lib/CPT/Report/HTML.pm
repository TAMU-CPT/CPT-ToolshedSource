package CPT::Report::HTML;
no warnings;
use Moose;
use Carp;
with 'CPT::Report';
use CGI;

has cgi => (
	is	    => 'rw',
	isa 	=> 'Any',
	default => sub {
		CGI->new();
	},
	# other attributes
);

sub header {
	my ($self) = @_;
	return $self->cgi()->start_html(
		-style => { -src => ['http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css','http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css'] }
	);
}

sub footer{
	my ($self) = @_;
	return $self->cgi()->end_html();
}
sub h1{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h1($addition));
}
sub h2{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h2($addition));
}
sub h3{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h3($addition));
}
sub h4{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h4($addition));
}
sub h5{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h5($addition));
}
sub h6{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->h6($addition));
}
sub p{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->p($addition));
}
sub b{
	my ($self, $addition) = @_;
	$self->a($self->cgi()->b($addition));
}

sub finalize_table{
	my ($self) = @_;
	my @td;
	if(defined $self->_table_header() && scalar @{$self->_table_header()} > 0 ){
		push(@td, $self->cgi->th($self->_table_header()));
	}
	foreach(@{$self->_table_data()}){
		push(@td, $self->cgi->td($_));
	}

	$self->a($self->cgi()->table(
			{-class => "table table-striped"},
			$self->cgi->Tr(\@td)
		)
	);

	# Reset for next usage
	$self->_table_header([]);
	$self->_table_data([]);
}

has _table_header => (
	is	    => 'rw',
	isa 	=> 'ArrayRef',
);
has _table_data => (
	is	    => 'rw',
	isa 	=> 'ArrayRef',
	default => sub { [] },
);


sub table_header {
	my ($self, @values) = @_;
	$self->_table_header(\@values);
}

sub table_row {
	my ($self, @values) = @_;
	my @current = @{$self->_table_data()};
	push(@current, \@values);
	$self->_table_data(\@current);
}

sub list_start {
	my ($self, $type) = @_;
	if($type ne 'number' && $type ne 'bullet'){
		carp 'Must use number or bullet as list type';
	}
	if($self->_list_type() eq 'number'){
		$self->a('<ol>');
	}else{
		$self->a('<ul>');
	}
	$self->_list_type($type);
}

sub list_end {
	my ($self) = @_;
	if($self->_list_type() eq 'number'){
		$self->a('</ol>');
	}else{
		$self->a('</ul>');
	}
}

sub list_element {
	my ($self, $element_text) = @_;
	$element_text =~ s{&}{&amp;}gso;
	$element_text =~ s{<}{&lt;}gso;
	$element_text =~ s{>}{&gt;}gso;
	$element_text =~ s{"}{&quot;}gso;
	$self->a(sprintf('<li>%s</li>', $element_text));
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Report::HTML

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
