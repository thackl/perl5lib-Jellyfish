
# Example for IPC::Run interface to STDIN/STDOUT/STDERR controlled process,
# inclduding "unbuffering" by piping through pseudo terminals.
# Here not required and hence not further developed

package Jellyfish::Query;

use warnings;
use strict;

use IO::File;

#use IPC::Open3;
use IPC::Run qw(start pump finish);
use Data::Dumper;

our $VERSION = '0.01';

##------------------------------------------------------------------------##

=head1 NAME 

Jellyfish.pm

=head1 DESCRIPTION

Perl api to query jellyfish hashes interactively in memory.

=head1 SYNOPSIS

=cut

=head1 CHANGELOG

=head2 0.01

=over

=item [Initial]

=back

=cut

=head1 TODO

=over

=back

=cut


##------------------------------------------------------------------------##

=head1 Class Attributes

=cut

our %OptLong = (
	'--both-strands' => undef,
	'--cary-bit' => undef,
	'--input' => undef,
	'--output' => undef,
	'--usage' => undef,
	'--help' => undef,
	'--version' => undef
);

our %OptShort2Long = (
	'-C' => '--both-strands',
	'-c' => '--cary-bit',
	'-i' => '--input',
	'-o' => '--output',
	'-h' => '--help',
	'-V' => '--version'
);

##------------------------------------------------------------------------##

=head1 Class METHODS

=cut

=head2 _Param_join (HASHREF, JOIN=STRING)

Joins a HASHREF, in scalar context to a parameter STRING with JOIN [" "],
 in LIST context to an parameter ARRAY, ignoring keys with undef values 
 and creating flag only values for ''.

  CLASS->_Param_join(HASHREF); # join with space
  CLASS->_Param_join(HASHREF, join => "\n") # join with newline

=cut

sub _Param_join{
	my $proto = shift;
	my $params = shift @_;
	my $p = {
		'join' => " ",
		'ignore' => [],
		@_
	};
	
	my %ignore;
	@ignore{@{$p->{ignore}}} = (1)x scalar @{$p->{ignore}}
		if @{$p->{ignore}};
	# params
	my @params;
	my $paramstring;
	foreach my $k (sort keys %$params){
		next if exists $ignore{$k};
		my $v = $params->{$k};
		# flag only is '', NOT '0' !!!
		next unless defined ($v);
		push @params, ($v ne '') ? ($k, $v) : $k;
	}
	
	return wantarray ? @params : join($p->{'join'}, @params);
}




##------------------------------------------------------------------------##

=head1 Constructor METHOD

=head2 new

=cut

sub new{
	my $proto = shift;
	my $self;
	my $class;
	
	# clone + overwrite
	if($class = ref $proto){ 
		die "cloning not supported";
		#return bless ({%$proto, @_}, $class);
	}else{
		$class = $proto;
	}
	
	#
	
	# init
	$self = {
		bin => 'jellyfish',
		cmd => 'query',
		hash => '',
		opt => {%OptLong},
		termchar => 'X',
		debug=>0,
		# overwrite
		@_ ,
		# protected
		_i => '',
		_o => '',
		_e => '',
		_pid => undef,
		_status => undef
	};
	
	# make all opt long
	foreach (keys %{$self->{opt}}){
		next if length $_ > 2;
		die "unknown option $_" unless exists $self->{opt}{$OptShort2Long{$_}};
		$self->{opt}{$OptShort2Long{$_}} = $self->{opt}{$_};
		delete $self->{opt}{$_};
	}
	
	bless $self, $proto;

	die 'hash required' unless $self->hash;
	
	# init interface
	$self->_init_interface();
	
	return $self;
}

sub DESTROY{
	my $self = shift;
	if($self->{_harness}){
		finish $self->{_harness} or die $?;
	};
}


##------------------------------------------------------------------------##

=head1 Object METHODS

=cut

=head2 query

=cut

sub query{
	my ($self, $kmers) = @_;
	my ($kmer) = $kmers =~ /(^\S+)/; # get the first kmer
	chomp($kmers); 
	my $term = $self->{termchar} x length $kmer;
	$kmers.= "\n$term\n";
	$self->{_i} = $kmers;
	$self->{_harness}->pump until $self->{_o} =~ /$term/; 
	return $self->{_o};
}

=head2 _init_interface

=cut

sub _init_interface{
	my $self = shift;
	
	# let IPC::Run do its magic :)	
	
	my @cmd = ($self->bin, $self->cmd, $self->_Param_join($self->{opt}), $self->hash);
	$self->{_harness} = start 
		debug=>$self->{debug},
		\@cmd, 
		\$self->{_i},
		'1>pty>',
		\$self->{_o},
		'2>pty>',
		\$self->{_e},
	or die "$?";
	
	return $self;
	
}

##------------------------------------------------------------------------##

=head1 Accessor METHODS

=cut

=head2 bin

Get/Set the bin to the binaries.

=cut

sub bin{
	my ($self, $bin) = @_;
	$self->{bin} = $bin if defined($bin);
	return $self->{bin};
}

=head2 cmd

Get/Set the cmd to the cmdaries.

=cut

sub cmd{
	my ($self, $cmd) = @_;
	$self->{cmd} = $cmd if defined($cmd);
	return $self->{cmd};
}

=head2 hash

Get/Set the hash to the hasharies.

=cut

sub hash{
	my ($self, $hash) = @_;
	$self->{hash} = $hash if defined($hash);
	return $self->{hash};
}



=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut



1;



