package threadeach;

use strict;
use vars qw($VERSION);
use threads;
use Carp;
use Text::Balanced ':ALL';

$VERSION = '1.0';
  

# LOAD FILTERING MODULE...
use Filter::Util::Call;

sub __();

my $offset;
my $debug=0;

sub debug
{
	$debug=shift;
}
sub import
{
	$offset = (caller)[2]+1;
	filter_add({}) unless @_>1 && $_[1] eq 'noimport';
	my $pkg = caller;
	no strict 'refs';
	for ( qw( on_defined on_exists ) )
	{
		*{"${pkg}::$_"} = \&$_;
	}
	*{"${pkg}::__"} = \&__ if grep /__/, @_;
	1;
}

sub filter
{
	my($self) = @_ ;
	local $threadeach::file = (caller)[1];

	my $status = 1;
	$status = filter_read(1_000_000);
	return $status if $status<0;
    	$_ = filter_blocks($_,$offset);
	$_ = "# line $offset\n" . $_ if $offset; undef $offset;
	return $status;
}


sub line
{
	my ($pretext,$offset) = @_;
	($pretext=~tr/\n/\n/)+($offset||0);
}

sub filter_blocks
{
	my ($source, $line) = @_;
	return $source unless $source =~ /threadeach|threadall|threadx/; #list of options here
	pos $source = 0;
	my $text = "";
	component: while (pos $source < length $source)
	{
		if ($source =~ m/(\G\s*use\s+threadeach\b)/gc)
		{
			$text .= q{use threadeach 'noimport'};
			next component;
		}
		my @pos;

		#look for threadeach instances #list of options here
		if (
		  $source =~ m/\G(\n*)(\s*)(threadeach)\b(?=\s*[(])/gc  #for the use line
		 || $source =~ m/\G(\n*)(\s*)(threadeach|threadall|threadx\d+)\b(?=\s*[(])/gc   #bare threadeach (@var)
		 || $source =~ m/\G(\n*)(\s*)(threadeach|threadall|threadx\d+)\s*(\$\w+)\b(?=\s*[(])/gc   #threadeach $var(@var)
		 || $source =~ m/\G(\n*)(\s*)(threadeach|threadall|threadx\d+)\s*((my|local|our)\s+\$\w+)\b(?=\s*[(])/gc   #threadeach my $var(@var)
		 )
		{
			my $f_name=rand_func_name();
			my $keyword = $3; 	#threadeach, forkeach, etc
			my $arg = $4;		#any my,our,local
			my $var;			#the var itself
			print "\tkeyword=$keyword\targ$arg\tvar=$var\n" if $debug;

			#test to see if there is a variable in the argument column i.e. threadeach my $var (@things)
			#unfortunately, have to have every kind of var assignment here
			#my, our, local, etc
			if($arg =~ m/^\$\w+$/ 
			 || $arg=~ m/^my\s+\$\w+$/
			 || $arg=~ m/^our\s+\$\w+$/
			 || $arg=~ m/^local\s+\$\w+$/
			 )
			{
				$var=$arg;
				$arg='';
			}
			#create the variable shift if needed
			#if $var is "my $x", then the sub will begin with "my $x = shift;" to get the variable
			if($var){$var="$var = shift;";}

			$text .= $1.$2;
			unless ($arg) {
				@pos = Text::Balanced::_match_codeblock(\$source,qr/\s*/,qr/\(/,qr/\)/,qr/[[{(<]/,qr/[]})>]/,undef) 
				or do {
					die "Bad $keyword statement (problem in the parentheses?) near $threadeach::file line ", line(substr($source,0,pos $source),$line), "\n";
				};
				$arg = filter_blocks(substr($source,$pos[0],$pos[4]-$pos[0]),line(substr($source,0,$pos[0]),$line));
			}
			@pos = Text::Balanced::_match_codeblock(\$source,qr/\s*/,qr/\{/,qr/\}/,qr/\{/,qr/\}/,undef)
			or do {
				die "Bad $keyword statement (problem in the code block?) near $threadeach::file line ", line(substr($source,0, pos $source), $line), "\n";
			};

			$arg=~s/^\s+//;		#get rid of leading whitespace in front of arg
			$arg=~s/^\((.*)\)$/$1/; #get rid of the parentheses around the array
			my $code = filter_blocks(substr($source,$pos[0],$pos[4]-$pos[0]),line(substr($source,0,$pos[0]),$line));

			#set the first part of the code block to have the variable part
			$code=~s/^\s+//;
			$code=~s/^\{//;
			$code="{$var\n$code";

			#threadx is a special case
			if($keyword=~m/threadx/)
			{
				my $count=$keyword;
				$count=~s/threadx(\d+)/$1/;
				$code="sub $f_name $code\n threadeach::threadsome(\\&$f_name,$count,$arg);\n";
			}
			else
			{
				$code="sub $f_name $code\n threadeach::$keyword(\\&$f_name,$arg);\n";
			}
			print "\tcode=$code\n" if $debug;
			$text .= $code;
			next component;
		}

		$source =~ m/\G(\s*(-[sm]\s+|\w+|#.*\n|\W))/gc;
		$text .= $1;
	}
	$text;
}

sub rand_func_name
{
	my $name='';
	my @letters=('A'..'Z');
	my $total=@letters;
	for(0..32){$name.=$letters[rand $total]}
	return $name;
}

sub on_exists
{
	my $ref = @_==1 && ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
	[ keys %$ref ]
}

sub on_defined
{
	my $ref = @_==1 && ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
	[ grep { defined $ref->{$_} } keys %$ref ]
}

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
	print "Running $how_many threads\n" if $debug;
        
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
		if(threads->list(threads::running)>0)#|| threads->list(threads::joinable)>0)
		{
			sleep(1)
		} #this is just so it doesn't spin its' wheels too fast while waiting
	}
}

1;
__END__
