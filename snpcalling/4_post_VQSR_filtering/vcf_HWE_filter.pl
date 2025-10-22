#!/usr/bin/perl


use warnings;
use strict;
use Data::Dumper;
use Getopt::Std;
use List::Util qw(sum);

my %flags;
getopts( "i:o:P:c:F:n:d:s:fprS", \%flags );
unless ( defined $flags{i} && $flags{o} )
{
        print "\nThis script takes the allele genotype calls from vcf file, calculates allele frequencies and conducts goodness-of-fit test based on Chi^2 distribution. This version, due to restrictions associated with inbreedin coefficient accepts DI- only, TRI- and TETRAPLOID calls will need to wait. THIS VERSION IS COMPATIBLE WITH GATK VCF\n\nUSAGE: vcf_HWE_filter.pl -i input -o output [options]\n\n";
	print "\t-i\t [FILE] input file\n";
	print "\t-o\t [FILE] output file\n";
	print "\t-P\t [FILE] if you want to run analyses on subpopulations, provide file with population defined in each line by comma separated indexes in format: POP:IND1,IND2,..,INDN\n";
        print "\t-c\t [FLOAT] Define Chi-square treshold for filtering [DEFAULT: X.XX with prob = 0.05 and dof = n-1, automatic for n between 2- and 6-ploid]\n";
	print "\t-F\t [FLOAT] Define Inbreeding coefficient for calculating HWE, implemented only for diploids as of now [DEFUALT: 0]\n";
	print "\t-f\t [BOOLEAN] Instead of calculating HWE, programme will help calculating inbreeding coefficient F by printing to outfile Hobs/Hexp for SNPs where Hobs/Hexp < 1 and minor allele frequency > 5%. F will be a median of these values\n";
	print "\t-n\t [INT] Define ploidy of your SNP calls [DEFAULT: 2]\n";
	print "\t-d\t [INT] Define minimum read depth cutoff for individuals to be used for HWE filter/calculate F [DEFAULT: 0]\n";
	print "\t-s\t [INT] Define minimum fraction of indviduals with calls to use for HWE filtering/calculating F [DEFAULT: 0]\n";
	print "\t-p\t [BOOLEAN] Switch p-value cutoff from 0.05 to 0.01 [DEFAULT: no]\n";
	print "\t-r\t [BOOLEAN] Print SFS report; works only if no subpopulations defined [DEFAULT: no]\n";
	print "\t-S\t [BOOLEAN] Filter singletons, not recommeneded at this point [DEFAULT: no]\n\n\n";	

        exit ;
}

### FILES AND FLAGS INIT

my $file = $flags{i};
my $outfile = $flags{o};

open(IN, "$file") or die "\nCannot open input\n";
open(OUT, ">$outfile") or die "\nCannot open output\n";


if (defined $flags{r}) {open(SUM, ">$outfile.sfs") or die "\nCannot open output\n";}
my %sfs;

my $pops = $flags{P};
if (defined $flags{P}) {open(POP, "$pops") or die  "\nCannot open population file\n";}

# INIT FILTERS

my $inbrd = 0;
if (defined $flags{F}) {$inbrd = $flags{F};}

print "Inbreeding coefficient defined as: $inbrd\n\n";

my $ploidy = 2;
if (defined $flags{n}) {$ploidy = $flags{n};}

print "Ploidy defined as: $ploidy\n\n";

if (int($ploidy) != $ploidy)
{
	die "ERROR: Ploidy must be an integer\n\n";
}

my $depth_cut = 0;
if (defined $flags{d}) {$depth_cut = $flags{d};}

my $num_cut = 0;
if (defined $flags{s}) {$num_cut = $flags{s};}


my @cutoffs = (3.84, 5.99, 7.81, 9.49, 11.07);
	
if (defined $flags{p}) {@cutoffs = (6.63, 9.21, 11.34, 13.28, 15.09);}

my $cutoff;
if (defined $flags{c}) {$cutoff = $flags{c};}
else {$cutoff = $cutoffs[$ploidy -2];}

if (defined $flags{p}) {print "Probability = 0.01\nDegrees of freedom = $ploidy-1\nChi-Square threshold = $cutoff\n\n"; }
else {print "Probability = 0.05\nDegrees of freedom = $ploidy-1\nChi-Square threshold = $cutoff\n\n";}

# READ IN POPULATIONS 

my %pops;
if (defined $flags{P}) 
{
	while(<POP>)
	{
		my @pline = split ":", $_;
		my @pind = split ",", $pline[1];
		$pops{$pline[0]} = \@pind;
	}
} 
# GENERATE POSSIBLE GENOTYPES

my @genotypes = split "", (0 x $ploidy);
push @genotypes,1;
for (my $i = 0; $i <= $ploidy; $i++)
{
	for (my $j = $ploidy-2; $j >= 0; $j--)
	{
		if ($j >= $i)
		{
			$genotypes[$i] = $genotypes[$i].0;
		} else {
			$genotypes[$i] = $genotypes[$i].1;
		}
	}
}

print "Genotypes: ", join "\t", @genotypes, "\n\n";

# GENERATE GENOTYPE WEIGHTS and INBREEDING CORRECTION SINGS

my @pascal = ("1", "1/1", "1/2/1", "1/3/3/1", "1/4/6/4/1", "1/5/10/10/5/1", "1/6/15/20/15/6/1");
my @weights = split "/", $pascal[$ploidy];
my %weights;

my @corr = (1,-1,1);
my %corr;

for (my $n = 0; $n <= $ploidy; $n++) 
{
	$weights{$genotypes[$n]} = $weights[$n];
	$corr{$genotypes[$n]} = $corr[$n];
}


				#print Dumper \%weights;


##### READ AND PARSE FILE #####

my $all_sites = 0;
my $HWE_sites = 0;
my $SING_sites =0;

while(<IN>)
{
	chomp;
	my @vcfline = split "\t", $_;
	if ($vcfline[0] =~ /^(\#\#FORMAT\=\<ID\=AD)/)
        {
		if (defined $flags{f}) {next;}
		print OUT "##FILTER=<ID=HWE_ALL,Description=\"Chi-square > $cutoff for total population\">\n";
		foreach (keys %pops)
		{
			print OUT "##FILTER=<ID=HWE_$_,Description=\"Chi-square > $cutoff for $_ population\">\n";
		} 
	}

	if ($vcfline[0] =~ /^(\#)/)
	{
		if ($vcfline[0] =~ /\#CHROM/)
        	{
			my @temp = (9 .. $#vcfline);
			$pops{"ALL"}=\@temp;
		}
		if (defined $flags{f}) {next;}
		print OUT $_, "\n"; 
		next;
	}

	my @F;
	if (defined $flags{f})
        {
		if ($vcfline[6] eq "Qual")
		{
			next;
		}
	}


## COUNT OBSERVED GENOTYPE FREQUENCIES
	foreach my $pop1 (sort keys %pops)
	{
		my %genotypes;
		for (@genotypes)
		{
			$genotypes{$_}=0;
		}
		foreach my $element (@vcfline[@{$pops{$pop1}}])
		{
			my @fields = split ":", $element;
			if (scalar @fields < 3 || $fields[2] eq ".")
			{
				next;
			}
			$fields[0] =~ s/\///g;
			my $gens = $fields[0];
			if ($fields[2] >= $depth_cut)
			{
				$genotypes{$gens}++;
			}
		}
					#print Dumper \%genotypes;
		
	
	## CALCULATE ALLELE FREQUENCIES
		my $total= 0;
		my $ref_count=0;
		my $alt_count=0;
	
		for my $elem (@genotypes)
		{
			$total += $genotypes{$elem}*$ploidy;
			my $ref = ($elem =~ tr/0//);
			my $alt = ($elem =~ tr/1//);
			$ref_count += $ref * $genotypes{$elem};
			$alt_count += $alt * $genotypes{$elem};
		}
					#print "$ref_count\t$alt_count\t$total\n";
		my $ref_freq = 0;
		my $alt_freq = 0;
		unless ($total == 0)
		{
			$ref_freq = $ref_count/$total;
			$alt_freq = $alt_count/$total;
		}
	## CALCULATE EXPECTED GENOTYPE FREQUENCIES
		my %expected;
		
		for my $elem2 (@genotypes)
		{
			my $ref = ($elem2 =~ tr/0//);
			my $alt = ($elem2 =~ tr/1//);
			$expected{$elem2} = ( $weights{$elem2}*($ref_freq**$ref)*($alt_freq**$alt) + $corr{$elem2}*$inbrd*$weights{$elem2}*$ref_freq*$alt_freq )*$total/$ploidy;
		}
					#print Dumper \%expected;
	
	## Inbreeding F values
	
		if (defined $flags{f})
		{
			if ($ref_freq > 0.05 && $alt_freq > 0.05) 
			{
				my $f = 1-($genotypes{"01"}/$expected{"01"});
				if ($f > 0)
				{
					push @F, $f;
				} else {
					push @F, "NA";
				}
			} else {
				push @F, "NA";
			}
			next;
		}


	## GOODNESS OF FIT
	
		my $chi=0;
	
		if ($ref_freq == 0 || $alt_freq == 0)
		{
			$chi = 0;
		} else {
			for my $elem3 (@genotypes)
			{
				if ($genotypes{$elem3} == $expected{$elem3})
				{
					$chi += 0;
				} else {
					$chi += (($genotypes{$elem3}-$expected{$elem3})**2)/$expected{$elem3}
				}
			}
					#print $chi, "\n";
					#last;
		}

## FILTERS
		my $no_ind = scalar @{$pops{$pop1}};
		my $SF = ($total/$ploidy)/$no_ind;	

	        if ($chi > $cutoff && $SF > $num_cut )
		{
			if ($vcfline[6] eq "PASS")
			{
				$vcfline[6] = "HWE_${pop1}";
			} else {
				$vcfline[6] .=";HWE_${pop1}";
			}
		} 

		if (defined $flags{S} && 2 > ($genotypes{"0001"}+$genotypes{"0011"}+$genotypes{"0111"}+$genotypes{"1111"}))
		{
			if ($vcfline[6] eq "PASS")
	                {
	                        $vcfline[6] = "SING_${pop1}";
	                } else {
	                        $vcfline[6] .=";SING_${pop1}";
	                }
		} 
	
	
		if (defined $flags{r} && $vcfline[6] eq "PASS")
		{
			$sfs{$alt_freq}++;
		}
	}
	if (defined $flags{f}) {print OUT join "\t",@F , "\n";next;}
	if ($vcfline[6] eq "PASS") {$HWE_sites++;}
	print OUT join "\t",@vcfline, "\n";
	$all_sites++;
}
	print "$HWE_sites out of $all_sites positions passed HWE filter at threshold: chi^2 = $cutoff (and singleton filter, if specified)\n\n";
## PRINT SUMMARY

if (defined $flags{r})
{
	foreach my $el (sort keys %sfs)
	{
		print SUM $el, "\t",$sfs{$el}, "\n";
	}
	close SUM;
}


## CLOSE

close IN;
close OUT;

__END__
