#!/usr/bin/perl
use warnings;
use strict;
use Threadeach;
use forks;

my $start=shift || usage();
my $end=shift || usage();
my $threads=shift || 10;

my @lines=Threadeach::threadsome(\&run_blag,$threads,$start..$end);

sub run_blag
{
	my $id=shift;
	if(-e "STOP_BLAG")	#end if the stop file exists (and remove it for laziness)
	{
		print "Found 'STOP' file, stopping main thread, others will finish\n";
		unlink("STOP");
		last;
	}
	my $cmd="bash blag.sh $id";
	print "$cmd\n";
	system($cmd);
}

sub usage
{
	print "usage: $0 <startid> <endid> [Optional: # of threads]\n";
	exit();
}
