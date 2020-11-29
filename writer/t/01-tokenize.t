#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

use lib "lib";
use_ok "Grammar";

cmp_deeply(Grammar::tokenize(""), [],
	'the empty string should tokenize as an empty list of tokens');

cmp_deeply(Grammar::tokenize("abcdef"), [{
	type  => 'IDENT',
	value => 'abcdef',
}], '"abcdef" should tokenize as [IDENT(abcdef)]');

cmp_deeply(Grammar::tokenize("abc def"), [
	{ type => 'IDENT', value => 'abc' },
	{ type => 'IDENT', value => 'def' },
], '"abc def" should tokenize as [IDENT(abc) IDENT(def)]');

cmp_deeply(Grammar::tokenize("<>[]():|;~"), [
	{ type => '<' },
	{ type => '>' },
	{ type => '[' },
	{ type => ']' },
	{ type => '(' },
	{ type => ')' },
	{ type => ':' },
	{ type => '|' },
	{ type => ';' },
	{ type => '~' },
], 'special characters auto-tokenize');

cmp_deeply(Grammar::tokenize("[50]"), [
	{ type => '[' },
	{ type => 'WEIGHT', value => 50 },
	{ type => ']' },
], 'weights tokenize properly');

cmp_deeply(Grammar::tokenize('"literal string"'), [{
	type  => 'STRING',
	value => 'literal string',
}], 'literal double-quoted strings should tokenize properly');

cmp_deeply(Grammar::tokenize('"a" "b" "c"'), [
	{ type => 'STRING', value => 'a' },
	{ type => 'STRING', value => 'b' },
	{ type => 'STRING', value => 'c' },
], 'multiple literals should not get munged together');


cmp_deeply(Grammar::tokenize('$thing'), [{
	type  => 'VARREF',
	value => 'thing',
}], 'variable references should tokenize properly');

cmp_deeply(Grammar::tokenize(
<<'EOF'
_ : "literal" <production> $var [25] ;
EOF
), [
	{ type => 'IDENT',  value => '_' },
	{ type => ':' },
	{ type => 'STRING', value => 'literal' },
	{ type => '<' },
	{ type => 'IDENT',  value => 'production' },
	{ type => '>' },
	{ type => 'VARREF', value => 'var' },
	{ type => '[' },
	{ type => 'WEIGHT', value => '25' },
	{ type => ']' },
	{ type => ';' },
],
	'a single production rule should tokenize properly');

cmp_deeply(Grammar::tokenize(
<<'EOF'
_ : <a>
  | <b>
  | "c"
  | $d
  ;
EOF
), [
	{ type => 'IDENT',  value => '_' },
	{ type => ':' },
	{ type => '<' }, { type => 'IDENT',  value => 'a' }, { type => '>' },
	{ type => '|' },
	{ type => '<' }, { type => 'IDENT',  value => 'b' }, { type => '>' },
	{ type => '|' },
	{ type => 'STRING',  value => 'c' },
	{ type => '|' },
	{ type => 'VARREF',  value => 'd' },
	{ type => ';' },
],
	'a multi-clause production rule should tokenize properly');

done_testing;
