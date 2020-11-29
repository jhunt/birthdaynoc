package Grammar;
use strict;
use warnings;

#
# $Grammar::stdlib provides some basic text formatting
# functions that are expected to be useful in a variety
# of contexts.
#
# If you don't specify an explicitly library set, the
# generator functions (genall, generate, etc.) will use
# this library, implicitly.
#
our $stdlib = {

	# ord($ref) - get numeric ordinal (i.e. '1st' from '1')
	ord => sub {
		my ($n) = @_;
		my $s = "$n";

		if ($s =~ m/1$/ && $s !~ m/11$/) { return "${s}st"; }
		if ($s =~ m/2$/ && $s !~ m/12$/) { return "${s}nd"; }
		if ($s =~ m/3$/ && $s !~ m/13$/) { return "${s}rd"; }
		return "${s}th";
	},
};

#
# Randomly generate a single sentence, given a set of input
# parameters and a standard library of functions.  Branches
# that reference undefined variables will be ignored.
#
# If no standard library is given (i.e. `$fns` is undef),
# the default $Grammar::stdlib will be used implicitly.
#
sub generate {
	my ($ast, $vars, $fns) = @_;
	$fns ||= $Grammar::stdlib;
	return adjoin(_generate_production($ast, $ast->{_}, $vars, $fns));
}

sub adjoin {
	my (@raw) = @_;

	my (@words, @hold);
	my $hold = 0;

	# W W P +++ P W P +++ P +++ P W
	for (@raw) {
		if (@hold && !ref($_) && !$hold) {
			push @words, join('', @hold);
			@hold = ();
		}
		push @hold, $_ unless ref($_);
		$hold = ref($_);
	}
	push @words, join('', @hold) if @hold;
	return join(' ', @words);
}

sub _pick_random {
	my ($from, $weight_fn) = @_;
	my @pool;

	for (@$from) {
		my $weight = $weight_fn ? $weight_fn->($_) : 1;
		while ($weight--) {
			push @pool, $_;
		}
	}

	return $pool[int(rand(scalar @pool))];
}

sub _generate_production {
	my ($ast, $production, $vars, $fns) = @_;

	my @branches = grep { _needs_met($_->{needs}, $vars, $fns) } @{ $production->{branches} };
	my $branch = _pick_random(\@branches, sub { $_[0]->{weight} || 10 });

	return _generate_rule($ast, $branch->{rule}, $vars, $fns);
}

sub _generate_rule {
	my ($ast, $rule, $vars, $fns) = @_;

	my @s;
	for my $r (@$rule) {
		if ($r->{type} eq 'literal') {
			push @s, $r->{value};

		} elsif ($r->{type} eq 'abut') {
			push @s, {};

		} elsif ($r->{type} eq 'reference') {
			die "reference to undefined var!" unless exists $vars->{$r->{value}};
			my $v = $vars->{$r->{value}};
			if ($r->{fn}) {
				die "reference to undefined function!" unless exists $fns->{$r->{fn}};
				$v = $fns->{$r->{fn}}->($v);
			}
			push @s, $v;

		} elsif ($r->{type} eq 'production') {
			@s = (@s, _generate_production($ast, $ast->{$r->{value}}, $vars, $fns));
		}
	}
	return @s;
}

#
# Exhaustively generate all possible sentences, given a set
# of input parameters and a standard library of functions.
#
# If no standard library is given (i.e. `$fns` is undef),
# the default $Grammar::stdlib will be used implicitly.
#
sub genall {
	my ($ast, $vars, $fns) = @_;
	$fns ||= $Grammar::stdlib;
	return [
		map { adjoin(@$_) }
		_genall_production($ast, $ast->{_}, $vars, $fns)
	];
}

sub _genall_production {
	my ($ast, $production, $vars, $fns) = @_;

	my @s;
	for my $br (grep { _needs_met($_->{needs}, $vars, $fns) } @{ $production->{branches} }) {
		@s = (@s, _genall_rules($ast, $br->{rule}, $vars, $fns));
	}
	return @s;
}

sub _genall_rules {
	my ($ast, $rules, $vars, $fns) = @_;

	my $base = [];
	for my $r (@$rules) {
		if ($r->{type} eq 'literal') {
			$base = _combine($base, [[$r->{value}]]);

		} elsif ($r->{type} eq 'abut') {
			$base = _combine($base, [[{}]]);

		} elsif ($r->{type} eq 'reference') {
			die "reference to undefined var!" unless exists $vars->{$r->{value}};
			my $v = $vars->{$r->{value}};
			if ($r->{fn}) {
				die "reference to undefined function!" unless exists $fns->{$r->{fn}};
				$v = $fns->{$r->{fn}}->($v);
			}
			$base = _combine($base, [[$v]]);

		} elsif ($r->{type} eq 'production') {
			$base = _combine($base, [_genall_production($ast, $ast->{$r->{value}}, $vars, $fns)]);
		}
	}
	return @$base;
}

sub _combine {
	my ($base, $suffix) = @_;
	if (@$base == 0) {
		return $suffix;
	}
	my @out;
	for my $b (@$base) {
		for my $s (@$suffix) {
			push @out, [@$b, @$s];
		}
	}
	return [@out];
}

sub parse {
	my $tokens = tokenize(@_);

	my $ast = {};
	while (my $t = shift @$tokens) {
		if ($t->{type} eq 'IDENT') {
			$ast->{$t->{value}} = _parse_rule($tokens);

		} else {
			die "parse error";
		}
	}

	_revdeps($ast, $ast->{_});
	return $ast;
}

sub _revdeps {
	my ($ast, $node) = @_;
	my @deps;
	for my $br (@{ $node->{branches} }) {
		my @direct = map { $_->{value} } grep { $_->{type} eq 'reference' } @{ $br->{rule} };
		my $need = @direct ? [[@direct]] : [];

		for my $r (grep { $_->{type} eq 'production' } @{ $br->{rule} }) {
			$need = _combine($need, _revdeps($ast, $ast->{$r->{value}}));
		}
		push @deps, @$need;
		$br->{needs} = $need;
	}
	return \@deps;
}

sub _needs_met {
	my ($needs, $vars) = @_;
	return 1 if @$needs == 0;

	for my $need (@$needs) {
		my $ok = 1;
		for my $var (@$need) {
			if (! exists $vars->{$var}) {
				$ok = 0;
				last;
			}
		}
		return 1 if $ok;
	}
	return 0;
}

sub _parse_rule {
	my ($tokens) = @_;
	my $t;

	$t = shift @$tokens;
	$t->{type} eq ':' or die "bad rule; should start with a ':'\n";

	my $rule = {};
	my $weight = undef;
	my @rules;
	while ($t = shift @$tokens) {
		# from here, we can get:
		#     a < IDENT >
		#     a $ IDENT
		#     a STRING
		#     a [ WEIGHT ]
		#    an ABUT
		#     a '|'
		#  or a ';'

		if ($t->{type} eq 'ABUT') {
			push @rules, { type => 'abut' };

		} elsif ($t->{type} eq '<') {
			$t = shift @$tokens or die "parse error: unterminated production reference\n";
			$t->{type} eq 'IDENT' or die "parse error: unexpected '$t->{type}' token after production reference opener\n";
			my $ref = $t->{value};
			$t = shift @$tokens or die "parse error: unterminated production reference\n";
			$t->{type} eq '>' or die "parse error: unexpected '$t->{type}' token after production reference\n";

			push @rules, { type => 'production', value => $ref };

		} elsif ($t->{type} eq 'VARREF') {
			push @rules, { type => 'reference', value => $t->{value} };

		} elsif ($t->{type} eq 'STRING') {
			push @rules, { type => 'literal', value => $t->{value} };

		} elsif ($t->{type} eq 'IDENT') {
			my $fn = $t->{value};
			$t = shift @$tokens or die "parse error: unrecognized functional application\n";
			$t->{type} eq '(' or die "parse error: unrecognized functional application\n";

			$t = shift @$tokens or die "parse error: unrecognized functional application\n";
			$t->{type} eq 'VARREF' or die "parse error: unrecognized functional application\n";
			my $var = $t->{value};

			$t = shift @$tokens or die "parse error: unrecognized functional application\n";
			$t->{type} eq ')' or die "parse error: unrecognized functional application\n";

			push @rules, { type => 'reference', fn => $fn, value => $var };

		} elsif ($t->{type} eq '[') {
			$t = shift @$tokens or die "parse error: unterminated branch weight\n";
			$t->{type} eq 'WEIGHT' or die "parse error: unexpected '$t->{type}' token after branch weight opener\n";
			$weight = $t->{value}; # FIXME don't allow duplicates
			$t = shift @$tokens or die "parse error: unterminated branch weight\n";
			$t->{type} eq ']' or die "parse error: unexpected '$t->{type}' token after branch weight\n";

		} elsif ($t->{type} eq '|' || $t->{type} eq ';') {
			push @{$rule->{branches}}, {
				rule   => [@rules],
				weight => $weight,
			};
			$weight = undef;
			@rules = ();

			if ($t->{type} eq ';') {
				return $rule;
			}

		} else {
			die "parse error";
		}
	}
	
	return {};
}

sub tokenize {
	my ($s) = @_;
	my @tokens;

	while ($s !~ m/\G$/gc) {
		$s =~ m/\G\s*/gc;

		if ($s =~ m/\G\+\+\+/gc) {
			push @tokens, {
				type => 'ABUT',
			};

		} elsif ($s =~ m/\G([a-zA-Z_-][a-zA-Z0-9_-]*)/gc) {
			push @tokens, {
				type  => 'IDENT',
				value => $1,
			};

		} elsif ($s =~ m/\G([<>\[\]():|;~])/gc) {
			push @tokens, {
				type => $1,
			};

		} elsif ($s =~ m/\G\$([a-zA-Z_][a-zA-Z0-9]*)/gc) {
			push @tokens, {
				type => 'VARREF',
				value => $1,
			};

		} elsif ($s =~ m/\G([0-9]+)/gc) {
			push @tokens, {
				type  => 'WEIGHT',
				value => $1,
			};

		} elsif ($s =~ m/\G"(.*?)"/gc) { # naive
			push @tokens, {
				type  => 'STRING',
				value => $1,
			};

		} elsif ($s =~ m/\G(.{1,20})/gc) { # for errors
			push @tokens, {
				type => 'ERROR',
				value => 'syntax error',
				at    => $1,
			};
			return @tokens;
		}
	}

	return \@tokens;
}

1;
