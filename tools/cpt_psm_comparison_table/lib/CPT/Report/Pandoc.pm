package CPT::Report::Pandoc;
no warnings;
use Moose;
with 'CPT::Report';
use Carp;

sub header {
	my ($self) = @_;
	return sprintf "%% %s\n%% %s\n%% %s\n\n", $self->{title}, $self->{date}, $self->{author};
}

sub footer{
	my ($self) = @_;
	return '';
}

sub h1{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n# %s\n\n", $addition));
}
sub h2{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n## %s\n\n", $addition));
}
sub h3{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n### %s\n\n", $addition));
}
sub h4{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n#### %s\n\n", $addition));
}
sub h5{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n##### %s\n\n", $addition));
}
sub h6{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n\n##### %s\n\n", $addition));
}

sub p{
	my ($self, $addition) = @_;
	$self->a(sprintf("\n%s\n", $addition));
}

sub list_start {
	my ($self, $type) = @_;
	if($type ne 'number' && $type ne 'bullet'){
		carp 'Must use number or bullet as list type';
	}
	$self->_list_type($type);
}

sub list_end {
	my ($self) = @_;
}

sub list_element {
	my ($self, $element_text) = @_;
	my $preceeding_char;
	if($self->_list_type() eq 'number'){
		$preceeding_char = '#';
	}else{
		$preceeding_char = '*';
	}
	$self->a(sprintf('%s %s', $preceeding_char, $element_text));
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Report::Pandoc

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
