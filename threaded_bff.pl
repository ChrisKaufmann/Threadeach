#!/usr/bin/perl
use warnings;
use strict;
use Threadeach;
use forks;

my $start=shift || usage();
my $end=shift || usage();
my $threads=shift || 10;

my @lines=Threadeach::threadsome(\&run_bff,$threads,$start..$end);

#function to run threaded
sub run_bff
{
	my $id=shift;
	if(-e "STOP")	#end if the stop file exists (and remove it for laziness)
	{
		print "Found 'STOP' file, stopping main thread, others will finish\n";
		unlink("STOP");
		last;
	}
	my $cookie=$id%$threads;	#cookie id is id modulo #of threads(100threads will have 0-99, etc)
	my $cmd="bash bff.sh $id cookie$cookie.txt";
	print "$cmd\n";
	system($cmd);
	unlink("cookie$cookie.txt");#may take a fraction longer, but I think it's cleaner to clean up here
}

sub usage
{
	print "usage: $0 <startid> <endid> [Optional: # of threads]\n";
	exit();
}
