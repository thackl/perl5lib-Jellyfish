#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use FindBin qw($RealBin);
use lib "$RealBin/../lib/";


#--------------------------------------------------------------------------#
=head2 load module

=cut

BEGIN { use_ok('Jellyfish'); }

my $Class = 'Jellyfish';

#--------------------------------------------------------------------------#
=head2 sample data

=cut


# create data file names from name of this <file>.t
(my $Dat_file = $FindBin::RealScript) =~ s/t$/dat/; # data
(my $Dmp_file = $FindBin::RealScript) =~ s/t$/dmp/; # data structure dumped
(my $Mer_file = $FindBin::RealScript) =~ s/t$/mer/; # data structure dumped

# slurp <file>.dat
#my $Dat = do { local $/; local @ARGV = $Dat_file; <> }; # slurp data to string
#my %Dat;
#@Dat{qw(pb1 il1 crp1 crp2)} = split(/(?<=\n)(?=@)/, $Dat);

# eval <file>.dump
my %Dmp;
@Dmp{qw(
	obj
	stats_S
	stats_A
	histo_S_t1
	histo_S_t0
	histo_A_t1
	histo_A_t0
	kmers_seq
	kmers
	kmers_S_t1
	kmers_S_t0
	kmers_A_t1
	kmers_A_t0
	kmers_nr
	kmers_nr_S
)} = do "$Dmp_file"; # read and eval the dumped structure


#--------------------------------------------------------------------------#
=head1 Class METHODS

=cut


#--------------------------------------------------------------------------#
=head2 new

=cut

my $obj = new_ok($Class, [hash => $Mer_file]);
subtest 'new object' => sub{
	foreach my $attr(keys %{$Dmp{obj}}){
		is($obj->{$attr}, $Dmp{obj}{$attr}, "attribute $attr")
	}
};

#--------------------------------------------------------------------------#
=head2 Accessors

=cut

subtest 'generics' => sub{
	can_ok($Class, 'bin');
	is($obj->bin(), $obj->bin, 'bin() get');
	$obj->bin('path/to/jellyfish');
	is($obj->bin(), 'path/to/jellyfish', 'bin() set');
	$obj->bin('jellyfish');
};	

#--------------------------------------------------------------------------#
=head2 Object METHODS

=cut


subtest '$obj->run' => sub{
	can_ok($Class, 'run');
	like($obj->run(['--help']), qr/^Usage:/, "run() --help");
	is($obj->run(['stats', $Mer_file]), $Dmp{stats_S}, "run() stats");
};

subtest '$obj->stats' => sub{
	can_ok($Class, 'stats');
	like($obj->stats(['--help']), qr/^Usage:/, "stats() --help");
	is(scalar $obj->stats([$Mer_file]), $Dmp{stats_S}, "stats() SCALAR");
	my @stats = $obj->stats([$Mer_file]);
	ok(eq_array(\@stats, $Dmp{stats_A}), "stats() LIST");
};

subtest '$obj->histo' => sub{
	can_ok($Class, 'histo');
	like($obj->histo(['--help']), qr/^Usage:/, "histo() --help");
	is(scalar $obj->histo([$Mer_file], table => 1), $Dmp{histo_S_t1}, "histo() SCALAR table => 1");
	is(scalar $obj->histo([$Mer_file], table => 0), $Dmp{histo_S_t0}, "histo() SCALAR table => 0");
	my @histo = $obj->histo([$Mer_file], table => 1);
	ok(eq_array(\@histo, $Dmp{histo_A_t1}), "histo() LIST table => 1");
	@histo = $obj->histo([$Mer_file], table => 0);
	ok(eq_array(\@histo, $Dmp{histo_A_t0}), "histo() LIST table => 0");

};


subtest '$obj->query' => sub{
	can_ok($Class, 'query');
	like($obj->query(['--help']), qr/^Usage:/, "query() --help");
	
	# kmers STRING, STRING ref, ARRAY ref
	# table => 0/1
	# context STRING/ARRAY
	my $kmers_AR = $Dmp{kmers};
	my $kmers_S = join("\n", @$kmers_AR)."\n";
	my $kmers_SR = \$kmers_S;
	
	my $kmers_nr_AR = $Dmp{kmers_nr};
	
	# kmers STRING, table => 1, STRING context
	is(scalar $obj->query([$Mer_file], kmers => $kmers_S), $Dmp{kmers_S_t1}, "query() STRING SCALAR table => 1");
	# kmers STRING ref, table => 0, STRING context
	is(scalar $obj->query([$Mer_file], kmers => $kmers_SR, table => 0), $Dmp{kmers_S_t0}, "query() STRINGREF SCALAR table => 0");
	# kmers ARRAY ref, table => 1, ARRAY context
	my @query = $obj->query([$Mer_file], kmers => $kmers_AR);
	ok(eq_array(\@query, $Dmp{kmers_A_t1}), "query() ARRAYREF LIST table => 1");
	# kmers ARRAY ref, table => 0, ARRAY context
	@query = $obj->query([$Mer_file], kmers => $kmers_AR, table => 0);
	ok(eq_array(\@query, $Dmp{kmers_A_t0}), "query() ARRAYREF LIST table => 0");

	is(scalar $obj->query(['--both-strands', $Mer_file], kmers => $kmers_nr_AR), $Dmp{kmers_nr_S}, "query() --both-strands");
	



};



done_testing();



