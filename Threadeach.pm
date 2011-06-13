package Threadeach;
use forks;
use warnings;
use strict;
#use threads;
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
	my $todo_index=0;

	#as long as there's anything running, waiting, or more to do
	while(threads->list(threads::running) || threads->list(threads::joinable) || $todo_index < @todos)
	{
		#join all the ones that are waiting to be joined back in
		foreach my $thr(threads->list(threads::joinable))
		{
			$thr->join();
		}
		#as long as there's more to do (and we're not over the limit), spawn more
		while($todo_index < @todos && threads->list(threads::running) < $how_many)
		{
			my $thr=threads->create($sub_handle,$todos[$todo_index]);
			$todo_index++;
		}
		sleep(1); #this is just so it doesn't spin its' wheels too fast while waiting
	}
}

1;
