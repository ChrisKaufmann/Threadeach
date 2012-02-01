use threadeach;
my $a="switch_test val";
my @b=(1,2,3,4,5,10);
my @c=('a','b','c');
my @d=('1','2','a','b');
my @e=('1','2','a','b');


print "Testing no declaration, shift: expect abc\n";
threadeach (@c) 
{
	my $a=shift;print "$a";
}
print "\n";
print "Testing variable, no scoping: expect 12ab\n";
threadeach $d (@d){print "$d";}
print "\n";
print "Testing my: expect 12ab\n"; 
threadeach my $e(@e){print "$e";}
print "\n";


print "Testing our: expect 12345\n";
threadeach our $f   (@b) {print $f}
print "\n";

print "Testing sub in array, expect long wait: 54321\n";
threadx10 my $g(reverse(1,2,3,4,10,1,1,1,1,1,1))
{sleep $g;print $g}
print "\n";
