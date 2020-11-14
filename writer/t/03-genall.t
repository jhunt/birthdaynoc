#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

use lib "lib";
use_ok "Grammar";

cmp_deeply(Grammar::_combine([[]], [['a'], ['b'], ['c']]),
	[['a'], ['b'], ['c']],
	'combine([[]], [[a] [b] [c]]) is just [[a] [b] [c]]');

cmp_deeply(Grammar::_combine([['foo'], ['FOO']], [['bar'], ['BAR']]),
	[['foo', 'bar'],
	 ['foo', 'BAR'],
	 ['FOO', 'bar'],
	 ['FOO', 'BAR']],
	'combine([[foo] [FOO]], [[bar] [BAR]]) is [[foo bar] [foo BAR] [FOO bar] [FOO BAR]]');

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: "foo" | "bar" | "quux" ;
EOF
)), [
	'foo',
	'bar',
	'quux',
],
	"genall should be able to generate all possible strings in the language");

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: <foo> <bar> ;
foo: "foo" | "FOO" ;
bar: "bar" | "BAR" ;
EOF
)), [
	'foo bar',
	'foo BAR',
	'FOO bar',
	'FOO BAR',
],
	"genall should be able to combine/expand all sub-productions");

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: <who> "loves" <whom> ;
who : "jughead" | "archie" ;
whom : "betty" | "veronica" ;
EOF
)), [
	'jughead loves betty',
	'jughead loves veronica',
	'archie loves betty',
	'archie loves veronica',
],
	"genall should be able to collapse [2] [1] [2] chains");

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: $somevar ;
EOF
), {
	somevar => 'FOO'
}), [
	'FOO'
], "variable references should resolve");

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: "foo is" $foo
 | "bar is" $bar
 ;
EOF
), {
	foo => 'defined',
}), [
	'foo is defined',
], "only branches referencing defined variables should resolve");

cmp_deeply(Grammar::genall(Grammar::parse(
<<'EOF'
_: "the" ord($a) "year"
 | "the" ord($b) "year"
 | "the" ord($c) "year"
 | "the" ord($d) "year"
 | "the" ord($e) "year"
 ;
EOF
), {
	a => 1,
	b => 2,
	c => 3,
	d => 4,
	e => 5,
}, {
	ord => sub {
		my ($n) = @_;
		my $s = "$n";

		if ($s =~ m/1$/ && $s !~ m/11$/) { return "${s}st"; }
		if ($s =~ m/2$/ && $s !~ m/12$/) { return "${s}nd"; }
		if ($s =~ m/3$/ && $s !~ m/13$/) { return "${s}rd"; }
		return "${s}th";
	},
}), [
	"the 1st year",
	"the 2nd year",
	"the 3rd year",
	"the 4th year",
	"the 5th year",
],
	'should be able to apply function calls to variables');

done_testing;
