#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

use lib "lib";
use_ok "Grammar";

my $last;
cmp_deeply($last = Grammar::parse(
<<'EOF'
_: <a>
 | <b>
 ;
a: "AYYY"
 | "ayyy"
 ;
b: "BEEE"
 | "beee"
 ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'production', value => 'a' }],
				weight => undef,
				needs  => [],
			},
			{
				rule   => [{ type => 'production', value => 'b' }],
				weight => undef,
				needs  => [],
			},
		],
	},
	a => {
		branches => [
			{
				rule   => [{ type => 'literal', value => 'AYYY' }],
				weight => undef,
				needs  => [],
			},
			{
				rule   => [{ type => 'literal', value => 'ayyy' }],
				weight => undef,
				needs  => [],
			},
		]
	},
	b => {
		branches => [
			{
				rule   => [{ type => 'literal', value => 'BEEE' }],
				weight => undef,
				needs  => [],
			},
			{
				rule   => [{ type => 'literal', value => 'beee' }],
				weight => undef,
				needs  => [],
			},
		]
	},
},
	'a multi-level production should parse without issue')
	or diag explain $last;

cmp_deeply($last = Grammar::parse(
<<'EOF'
_: "foo" | "bar" | "quux" ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'literal', value => 'foo' }],
				weight => undef,
				needs  => [],
			},
			{
				rule   => [{ type => 'literal', value => 'bar' }],
				weight => undef,
				needs  => [],
			},
			{
				rule   => [{ type => 'literal', value => 'quux' }],
				weight => undef,
				needs  => [],
			},
		]
	}
},
	'a three-branch, equal-weighted alternate top rule should parse correctly')
	or diag explain $last;

cmp_deeply($last = Grammar::parse(
<<'EOF'
_: "foo is" $foo
 | "bar is" $bar
 ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'literal',   value => 'foo is' },
				           { type => 'reference', value => 'foo' }],
				weight => undef,
				needs  => [['foo']],
			},
			{
				rule   => [{ type => 'literal',   value => 'bar is' },
				           { type => 'reference', value => 'bar' }],
				weight => undef,
				needs  => [['bar']],
			},
		],
	},
},
	'immediate variable references should be identified in needs')
	or diag explain $last;

cmp_deeply($last = Grammar::parse(
<<'EOF'
_: "foo is" <foo>
 | "bar is" <bar>
 ;
foo: $foo | $FOO ;
bar: $bar | $BAR ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'literal',    value => 'foo is' },
				           { type => 'production', value => 'foo' }],
				weight => undef,
				needs  => [['foo'], ['FOO']],
			},
			{
				rule   => [{ type => 'literal',    value => 'bar is' },
				           { type => 'production', value => 'bar' }],
				weight => undef,
				needs  => [['bar'], ['BAR']],
			},
		],
	},
	foo => {
		branches => [
			{
				rule   => [{ type => 'reference', value => 'foo' }],
				weight => undef,
				needs  => [['foo']],
			},
			{
				rule   => [{ type => 'reference', value => 'FOO' }],
				weight => undef,
				needs  => [['FOO']],
			},
		],
	},
	bar => {
		branches => [
			{
				rule   => [{ type => 'reference', value => 'bar' }],
				weight => undef,
				needs  => [['bar']],
			},
			{
				rule   => [{ type => 'reference', value => 'BAR' }],
				weight => undef,
				needs  => [['BAR']],
			},
		],
	},
},
	'indirect variable references should be identified in needs')
	or diag explain $last;

cmp_deeply($last = Grammar::parse(
<<'EOF'
_: $mixed <a>
 | $mixed <b>
 ;
a: $foo | $bar ;
b: $bar | $baz ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'reference',  value => 'mixed' },
				           { type => 'production', value => 'a' }],
				weight => undef,
				needs  => [['mixed', 'foo'], ['mixed', 'bar']], # OR
			},
			{
				rule   => [{ type => 'reference',  value => 'mixed' },
				           { type => 'production', value => 'b' }],
				weight => undef,
				needs  => [['mixed', 'bar'], ['mixed', 'baz']], # OR
			},
		]
	},
	a => {
		branches => [
			{
				rule   => [{ type => 'reference', value => 'foo' }],
				weight => undef,
				needs  => [['foo']],
			},
			{
				rule   => [{ type => 'reference', value => 'bar' }],
				weight => undef,
				needs  => [['bar']],
			},
		]
	},
	b => {
		branches => [
			{
				rule   => [{ type => 'reference', value => 'bar' }],
				weight => undef,
				needs  => [['bar']],
			},
			{
				rule   => [{ type => 'reference', value => 'baz' }],
				weight => undef,
				needs  => [['baz']],
			},
		]
	}
},
	'mixed-levels of variable references integrate as they percolate up the stack')
	or diag explain $last;

cmp_deeply($last = Grammar::parse(
<<'EOF'
_: "happy" ord($year)
 ;
EOF
), {
	_ => {
		branches => [
			{
				rule   => [{ type => 'literal', value => 'happy' },
				           { type => 'reference', fn => 'ord', value => 'year' }],
				weight => undef,
				needs  => [['year']],
			},
		]
	},
},
	'functional application should parse and influence dependencies')
	or diag explain $last;

done_testing;
