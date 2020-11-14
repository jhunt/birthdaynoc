package Grammar;
use strict;
use warnings;

sub genall {
	my ($ast, $vars, $fns) = @_;
	return [map { join(' ', @$_) } _genall_production($ast, $ast->{_}, $vars, $fns)];
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
		#     a '|'
		#  or a ';'

		if ($t->{type} eq '<') {
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

		if ($s =~ m/\G([a-zA-Z_-][a-zA-Z0-9_-]*)/gc) {
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

		} elsif ($s =~ m/\G([0-9]+)%/gc) {
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
