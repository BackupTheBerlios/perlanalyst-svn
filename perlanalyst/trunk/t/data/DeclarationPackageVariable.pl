# $a in the current package
our $a;
my $not_a;

# switch to package A
package A;

# $a in package A
our $a;
my $not_a;

# switch to package B
package B;

# $a and $b in package B
our ($a, $b);
