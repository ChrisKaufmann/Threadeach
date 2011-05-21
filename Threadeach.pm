package Threadeach;
use warnings;
use strict;
use threads;
use vars qw($VERSION);
$VERSION='0.001';

#attempt to get the number of cpus, or guess
sub numcpus
{
	eval"use Sys::CPU;return Sys::CPU::cpu_count();"
	or return 4; #some arbitrary number
}

#spawn one thread for each cpu on the box
sub threadeach
{
	my $sub_handle=shift;
	my $procs=numcpus();
	return threadsome($sub_handle,$procs,@_);
}

#spawn a thread for every single member of the array passed
sub threadall
{
	my $sub_handle=shift;
	return threadsome($sub_handle,@_-1,@_);
}

#actually do the lifting of the threading, with a defined number of max threads
sub threadsome
{
	my $sub_handle=shift;
	my $how_many=shift;
	my @todos=@_;
	my @returns = (); #it'll return everything in the same order as passed.  :)

	my %list=();	#for maintaining the order as passed
	my $todo_index=0;

	#as long as there's anything running, waiting, or more to do
	while(threads->list(threads::running) || threads->list(threads::joinable) || $todo_index < @todos)
	{
		#first, join all the ones that are waiting to be joined back in
		foreach my $thr(threads->list(threads::joinable))
		{
			#and put any returned data into the returns array in the right spot.
			@returns[$list{$thr->tid()}]=$thr->join();
		}
		#as long as there's more to do (and we're not over the limit), spawn more
		while($todo_index < @todos && threads->list(threads::running) < $how_many)
		{
			my $thr=threads->create($sub_handle,$todos[$todo_index]);
			$list{$thr->tid()}=$todo_index;
			$todo_index++;
		}
		sleep(1); #this is just so it doesn't spin its' wheels too fast while waiting
	}
	return @returns;
}

1;
