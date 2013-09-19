package Jellyfish;

use warnings;
use strict;

use IPC::Run qw(start pump finish);
use Digest::MD5 qw(md5);

our $VERSION = '0.02';


##------------------------------------------------------------------------##

=head1 NAME 

Jellyfish.pm

=head1 DESCRIPTION

Class for handling Jellyfish, and in particular to provide an interactive 
 perl api to a jellyfish hash in memory.

=head1 SYNOPSIS

=cut

=head1 CHANGELOG

=cut

=head2 0.02

=over

=item [Feature] Submitting each query call for a bunch of kmers as a 
 single call performs very poorly. query() now sets up a interactive 
 interface which keeps a Query instance alive as long as options and 
 hash don't change and submits all calls to this interface.

=back

=cut

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
		query_term_char => 'x',
		_query => {md5 => ''},
	};
	
	return bless $self, $proto;
}


sub DESTROY{
	my $self = shift;
	if($self->{_query}{harness}){
		finish $self->{_query}{harness} or die $?;
	};
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
 SCALAR context a newline separated string is returned, in ARRAY context,
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
	

	# DEPREACTED: $self->run([$cmd, @$opt], $kmers, \$re);

	# compute a "id" from $@opt which will be the same as long as the same
	#  hash is queried with identical options
	my $md5 = md5(join("", @$opt));

	# init interface unless it already exists
	$self->_query_init_interface($cmd, $opt, $md5) unless $self->{_query}{md5} eq $md5;
	
	# add query interface terminator
	my ($kmer) = $$kmers =~ /(^\S+)/; # get the first kmer
	$self->{_query}{term} = $self->{_query}{termchar} x length $kmer;
	$$kmers.= $self->{_query}{term}."\n";

	# query kmers
	my $re = $self->_query_run($kmers);
	
	
	# process and return result
	if(wantarray){
		my @re = split(/\s/, $$re);
		chomp @re;
		if ($p{table}){
			return @re;
		}else{
			my $i=0;
			return grep{$i++ % 2}@re;
		}
	}elsif(! $p{table}){
		chomp $$re;
		my @re = split(/\s/, $$re);
		chomp @re;
		# every other element
		my $i=0; 
		return join("\n", grep{$i++ % 2}@re )."\n"
	}else{
		return $$re;
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

=head1 Private METHODS

=cut

=head2 _init_query_interface

=cut

sub _query_init_interface{
	my ($self, $cmd, $opt, $md5) = @_;
	die "md5 required" unless $md5;
	$self->{_query}={
		termchar => $self->{query_term_char},
		md5 => $md5,
	};
	
	$self->{_query}{md5} = $md5;
	$self->{_query}{harness} = start 
		#debug=>1,
		[$self->bin, $cmd, @$opt], 
		\$self->{_query}{i},
		'1>pty>',
		\$self->{_query}{o},
		'2>pty>',
		\$self->{_query}{e},
	or die "$?";
}


=head2 _query_interface

=cut

sub _query_run{
	my ($self, $kmers) = @_;
	$self->{_query}{i} = $$kmers;
	$self->{_query}{harness}->pump until $self->{_query}{o} =~ /$self->{_query}{term}/; 
	die $self->{_query}{e} if $self->{_query}{e};
	# fix \r from >pty>
	my $re = $self->{_query}{o};
	$self->{_query}{o} = ''; # clean out
	$self->{_query}{e} = ''; # clean out
	
	
	$re =~ tr/\r//d;
	
	# remove and check terminator
	$re =~ s/([^\n]+)\n$//;
	my ($term, $tcount) = split(/\s/, $1);
	unless ($tcount == 0){
		die "bad termchar: kmer '$term' has count '$tcount' in hash" 
	}
	return \$re;
}


=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut



1;



