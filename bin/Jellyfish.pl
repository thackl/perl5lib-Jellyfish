use warnings;
use strict;

use lib '../lib';
use Jellyfish;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $kmers = join("\n", qw(ATGC ATTA TTAT))."\n";
my @opt = qw(--both-strands);
my @arg = qw(../t/01jellyfish.mer);
my $out;
my $jf = Jellyfish->new;
print Dumper($jf);
=pod
print $jf->run(['--help']);

print $jf->query(['--help']);
my $kc1 = $jf->query([@opt, @arg], kmers => \$kmers);
my $kc2 = $jf->query([@opt, @arg], kmers => \$kmers, table => 1);
my @kc1 = $jf->query([@opt, @arg], kmers => \$kmers);
my @kc2 = $jf->query([@opt, @arg], kmers => \$kmers, table => 1);

print Dumper({
	kc1_S => $kc1,
	kc2_S => $kc2, 
	kc1_A => \@kc1, 
	kc2_A => \@kc2,
});

print $jf->histo(['--help']);
my $kh1 = $jf->histo([@arg]);
my $kh2 = $jf->histo([@arg], table => 1);
my @kh1 = $jf->histo([@arg]);
my @kh2 = $jf->histo([@arg], table => 1);

print Dumper({
	kh1_S => $kh1,
	kh2_S => $kh2,
	kh1_A => \@kh1,
	kh2_A => \@kh2,
});
=cut

my %stats = $jf->stats([@arg]);
print Dumper(\%stats);

