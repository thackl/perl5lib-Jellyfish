package Jellyfish;

use warnings;
use strict;

use IPC::Run;

our $VERSION = '0.01';


##------------------------------------------------------------------------##

=head1 NAME 

Jellyfish.pm

=head1 DESCRIPTION

Class for handling Jellyfish, and in particular to provide an interactive 
 perl api to a jellyfish hash in memory.

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


##------------------------------------------------------------------------##

=head1 Class METHODS

=cut


##------------------------------------------------------------------------##

=head1 Constructor METHOD

=head2 new

Create a new Jellyfish handler.

  $jf = Jellyfish->new(
    bin => '/path/to/jellyfish
  );

=cut

sub new{
	my $proto = shift;
	my $self;
	my $class;
	
	# object method -> clone + overwrite
	if($class = ref $proto){ 
		return bless ({%$proto, @_}, $class);
	}

	# class method -> construct + overwrite
	# init empty obj
	$self = {
		bin => 'jellyfish',
	};
	
	return bless $self, $proto;
}




##------------------------------------------------------------------------##

=head1 Object METHODS

=head2 run

NOTE: Only use run() directly if you really need it. Use the command methods
 below directly to get what you need.

Generic. Run a jellyfish command and retrieve results. Results are only 
 returned stringified if no <IPC::Run io stuff> is provided. Else, you will
 explicitly have to specify, where output should go to (STRING, FILEHANDLE, 
 FILE...).

  # simple
  $out = $jf->run([histo, '--both-strands', 'path/to/jf_kmer_hash']);
  
  # io stuff, Input (STDIN) from SCALAR, OUTPUT to filehandle
  my $kmers = "ATGC\nAATT\n";
  $jf->run([query, '--both-strands', 'path/to/jf_kmer_hash'], \$kmers, '>pipe', \*OUT);

  # jellyfish --help
  print $jf->run([--help]);
  
=cut

sub run{
	my $self = shift;
	my $cmd = shift;
	my @cmd = ($self->bin, @$cmd);
	my ($in, $out, $err) = (undef, '', '');
	my $h = IPC::Run::run \@cmd, @_ ? @_ : (\$in, \$out, \$err) or die "$err\n$?";
	warn $err if length $err; # print non fatal warnings
	return $out;
}

=head2 stats

Retrieve stats of a jellyfish hash. Returns raw STRING in SCALAR context, 
 a splitted LIST in LIST context.

  $stats = $jf->stats;
  %stats = $jf->stats;

=cut

sub stats{
	my $cmd = 'stats';
	my $self = shift;
	my $opt = @_%2 ?  shift : [];
	my %p = (
		@_
	);
	
	# run cmd
	my $re = '';
	$self->run([$cmd, @$opt], \undef, \$re);

	# process and return result
	if(wantarray){
		chomp $re;
		my @re = split(/\s+/, $re);
		chomp @re;
		return @re;
	}else{
		return $re;
	}
}


=head2 histo

Retrieve histogram informations from jellyfish hash. Returns raw STRING in 
 SCALAR context, a splitted LIST in LIST context. Use table=>1/0 to modify 
 output. See query() for details. 

  $stats = $jf->histo;
  %stats = $jf->histo;

=cut

sub histo{
	my $cmd = 'histo';
	my $self = shift;
	my $opt = @_%2 ?  shift : [];
	my %p = (
		table => 1,
		@_
	);
	
	# run cmd
	my $re = '';
	if($p{table}){
		$self->run([$cmd, @$opt], \undef, \$re);
	}else{
		my @jelly = ($self->bin, $cmd, @$opt);
		my @cut = ('cut','-f', '2','-d', ' ');
		$self->run([$cmd, @$opt], \undef, '|', \@cut, \$re);
	}
	
	# process and return result
	if(wantarray){
		chomp $re;
		my @re = split(/\s+/, $re);
		chomp @re;
		return @re;
	}else{
		return $re;
	}
}




=head2

Query a list of kmers against a given hash and retrieve counts. For table=>1
 results are in format "KMER COUNT", table=>0 produces counts only. In 
 SCALAR context a newline separated string is returned, in ARRAY context, a
 (KMERS and) COUNTS are individual items of a LIST.

Kmers can be provided either as STRING, STRING reference or ARRAY reference.

  print $jf->query(['--help']);
  # the command line help to 'jellyfish query'

  my $kmers = $jf->query(
    ['--both-strands', 'path/to/jf_kmer_hash'], 
    kmers => "ATTA\nTATT",  # string
    table => 0  # default
  );
  
  $kmers;
  # '0
  #  1'

  my $kmers = $jf->query(
    ['--both-strands', 'path/to/jf_kmer_hash'], 
    kmers => [qw(ATTA TATT)], 
    table => 1 
  );
  
  $kmers;
  # 'ATTA 0
  #  TATT 1'
  
  my @kmers = $jf->query(
    ['--both-strands', 'path/to/jf_kmer_hash'], 
    kmers => [qw(ATTA TATT)], 
  );
  
  @kmers;
  # '0','1'
  
  my %kmers = my @kmers = $jf->query(
    ['--both-strands', 'path/to/jf_kmer_hash'], 
    kmers => [qw(ATTA TATT)], 
    table => 1,
  );
  
  @kmers;
  # 'ATTA',0,'TATT','1'
  %kmers
  # 'ATTA' => 0, 'TATT' => 1
  
=cut

sub query{
	my $cmd = 'query';
	my $self = shift;
	my $opt = @_%2 ?  shift : [];
	my %p = (
		table => 1,
		kmers => '',
		@_
	);
	
	# short-cut options like --help
	unless ($p{kmers}){
		return $self->run([$cmd, @$opt]);
	}

	# handle kmer inputs
	my $kmers;
	if(! ref $p{kmers}){
		# make sure there is trailing "\n"
		chomp $p{kmers};
		$p{kmers}.="\n";
		$kmers = \$p{kmers};
	}elsif(ref $p{kmers} eq 'ARRAY'){
		$p{kmers} = join("\n", @{$p{kmers}});
		$p{kmers}.="\n";
		$kmers = \$p{kmers};
	}elsif(ref $p{kmers} eq 'SCALAR'){
		$kmers = $p{kmers};
	}else{
		die 'kmers neither STRING nor SCALAR ref nor ARRAY ref'
	}
	
	# run cmd
	my $re = '';
	if($p{table}){
		$self->run([$cmd, @$opt], $kmers, \$re);
	}else{
		my @jelly = ($self->bin, $cmd, @$opt);
		my @cut = ('cut','-f', '2','-d', ' ');
		$self->run([$cmd, @$opt], $kmers, '|', \@cut, \$re);
	}
	
	# process and return result
	if(wantarray){
		chomp $re;
		my @re = split(/\s+/, $re);
		chomp @re;
		return @re;
	}else{
		return $re;
	}
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


##------------------------------------------------------------------------##

=head1 Accessor METHODS

=cut

=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut



1;



