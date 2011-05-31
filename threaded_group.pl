#!/usr/bin/perl
use warnings;
use strict;
use Threadeach;

my $id_file=shift || usage();
my $threads=shift || 10;

die("file $id_file doesn't exist") unless -e $id_file;
my @ids=`cat $id_file`;chomp(@ids);
my @lines=Threadeach::threadsome(\&run_bff,$threads,@ids);

sub run_bff
{
	my $id=shift;
	my $cookie=$id%$threads;
	my $cmd="./bgf.sh $id cookie$cookie.txt";
	print "$cmd\n";
	my $out=system($cmd);
	$out=undef;
	$id=undef;
	$cookie=undef;
	$cmd=undef;
}

sub usage
{
	print "usage: $0 group_file [Optional: # of threads] [optional: max groupsize]\n";
	exit();
}
