package YAPE::Regex::Explain;

use lib "/home/jpinyan/lib/perl5/site_perl/5.005";
use YAPE::Regex 'YAPE::Regex::Explain';
use strict;
use vars '$VERSION';


$VERSION = '1.00';


my $format = << 'END';
^<<<<<<<<<<<<<<<<~~    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

END

my $br;

my %modes = ( on => '', off => '' );

my %exp = (

  # anchors
  '\A' => 'the beginning of the string',
  '^' => 'the beginning of the string',
  '^m' => 'the beginning of a "line"',
  '\z' => 'the end of the string',
  '\Z' => 'an optional \n followed by the end of the string',
  '$' => 'an optional \n followed by the end of the string',
  '$m' => 'an optional \n followed by the end of a "line"',
  '\G' => 'where the last m//g left off',
  '\b' => 'the boundary between a word char (\w) and something that is not
           a word char',
  '\B' => 'the boundary between a non-word char (\W) and something that is not
           a non-word char',
  
  # quantifiers
  '*' => '0 or more times',
  '+' => '1 or more times',
  '?' => 'optional',
  
  # macros
  '\w' => 'word characters (a-z, A-Z, 0-9, _)',
  '\W' => 'non-word characters (all but a-z, A-Z, 0-9, _)',
  '\d' => 'digits (0-9)',
  '\D' => 'non-digits (all but 0-9)',
  '\s' => 'whitespace (\n, \r, \t, \f, and " ")',
  '\S' => 'non-whitespace (all but \n, \r, \t, \f, and " ")',

  # dot
  '.' => 'any character except \n',
  '.s' => 'any character',

  # alt
  '|' => "OR",

  # flags
  'i' => 'case-insensitive',
  '-i' => 'case-sensitive',
  'm' => 'with ^ and $ matching start and end of line',
  '-m' => 'with ^ and $ matching normally',
  's' => 'with . matching \n',
  '-s' => 'with . not matching \n',
  'x' => 'disregarding whitespace and comments',
  '-x' => 'matching whitespace and # normally',

);

my %trans = (
  '\a' => q('\a' (alarm)),
  '\b' => q('\b' (backspace)),
  '\e' => q('\e' (escape)),
  '\f' => q('\f' (form feed)),
  '\n' => q('\n' (newline)),
  '\r' => q('\r' (carriage return)),
  '\t' => q('\t' (tab)),
);


sub explain {
  my $self = shift;
  local $^A = << "END";
The regular expression:

  @{[ $self->display ]}

matches as follows:
  
NODE                   EXPLANATION
====                   ===========
END
  
  my @nodes = @{ $self->{TREE} };
  while (my $node = shift @nodes) {
    $node->explanation;
  }
  
  $br = 0;
  return $^A;
}


sub YAPE::Regex::Explain::Element::extra_info {
  my $self = shift;    
  my ($q,$ng) = ($self->quant, $self->ngreed);
  my $ex = '';
  
  $q =~ s/.\?$//;
  $q =~ /(\d+),?(\d*)/ and
    ($q = $2 ? "between $1 and $2 times" : "at least $1 times");

  $ex .= ' (' . ($exp{$q} || $q) if $q;
  $ex .= ' (matching the least amount possible)' if $ng;
  $ex .= ')' if $q;
  
  return $ex;
}


sub YAPE::Regex::Explain::Element::handle_flags {
  my $self = shift;
  my ($prev_on, $prev_off) = @modes{qw( on off )};
  
  for (split //, $self->{ON}) {
    $modes{on} .= $_ if index($modes{on},$_) == -1;
  }
  my $on = $modes{on} = join "", sort split //, $modes{on};

  $modes{off} =~ s/[$on]+//g if length $on;

  for (split //, $self->{OFF}) {
    $modes{off} .= $_ if index($modes{off},$_) == -1;
  }
  my $off = $modes{off} = join "", sort split //, $modes{off};

  $modes{on} =~ s/[$off]+//g if length $off;

  my $exp = '';

  if ($modes{on} ne $prev_on) {
    for (split //, $modes{on}) { $exp .= ' (' . $exp{$_} . ')' }
  }
  
  if ($modes{off} ne $prev_off) {
    for (split //, $modes{off}) { $exp .= ' (' . $exp{-$_} . ')' }
  }

  return $exp;
}


sub YAPE::Regex::Explain::anchor::explanation {
  my $self = shift;
  my $type = $self->{TEXT};
  $type .= 'm' if
    ($type eq '^' or $type eq '$') and
    $modes{on} =~ /m/;

  my $explanation = $exp{$type} . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::macro::explanation {
  my $self = shift;
  my $type = $self->text;

  my $explanation = $exp{$type} . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::oct::explanation {
  my $self = shift;
  my $n = oct($self->{TEXT});

  my $explanation = "character $n" . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::hex::explanation {
  my $self = shift;
  my $n = hex($self->{TEXT});

  my $explanation = "character $n" . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::ctrl::explanation {
  my $self = shift;
  my $c = $self->{TEXT};

  my $explanation = "^$c" . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::slash::explanation {
  my $self = shift;

  my $explanation =
    ($trans{$self->text} || "'$self->{TEXT}'") .
    $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::any::explanation {
  my $self = shift;
  my $type = '.';
  $type .= 's' if $modes{on} =~ /s/;

  my $explanation = $exp{$type} . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::text::explanation {
  my $self = shift;
  my $text = $self->text;
  
  $text =~ s/\n/\\n/g;
  $text =~ s/\r/\\r/g;
  $text =~ s/\t/\\t/g;
  $text =~ s/\f/\\f/g;
  $text =~ s/'/\\'/g;
  
  my $explanation = "'$text'" . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::alt::explanation {
  my $self = shift;

  my $explanation = $exp{'|'};
  my $string = $self->string;
  
  my $oldfmt = $format;
  $format =~ s/ (\^<+)/$1 /g;
  $format =~ s/  /~~/;
  formline($format, $string, $explanation);
  ($format = $oldfmt) =~ s/  /~~/;

}


sub YAPE::Regex::Explain::backref::explanation {
  my $self = shift;

  my $explanation =
    "what was matched by capture \\$self->{TEXT}" . $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::class::explanation {
  my $self = shift;

  my $explanation = "any character";
  $explanation .= $self->{NEG} ? " except: " : " of: ";

  while ($self->{TEXT} =~ /(\\?.)/sg) {
    $explanation .= ($trans{$1} || $exp{$1} || "'$1'") . ", ";
  }
  
  substr($explanation,-2) = $self->extra_info;
  my $string = $self->string;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::comment::explanation { }


sub YAPE::Regex::Explain::whitespace::explanation { }


sub YAPE::Regex::Explain::flags::explanation {
  my $self = shift;
  my $string = $self->string;
  my $explanation =
    'set flags for this block' .
    $self->handle_flags;

  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::group::explanation {
  my $self = shift;
  my $explanation =
    'group, but do not capture' .
    $self->handle_flags .
    $self->extra_info .
    ":";
  my $string = $self->string;
  
  formline($format, $string, $explanation);

  my %old = %modes;

  my $oldfmt = $format;
  $format =~ s/\^<<(<+)/  ^$1/g;
  $format =~ s/  /~~/;
  $_->explanation for @{ $self->{CONTENT} };
  ($format = $oldfmt) =~ s/  /~~/;
  
  $string = ')' . $self->quant;
  $explanation = $self->extra_info;

  %modes = %old;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::capture::explanation {
  my $self = shift;
  my $explanation =
    'group and capture to \\' .
    ++$br .
    $self->extra_info .
    ":";
  my $string = $self->string;
  
  formline($format, $string, $explanation);

  my %old = %modes;

  my $oldfmt = $format;
  $format =~ s/\^<<(<+)/  ^$1/g;
  $format =~ s/  /~~/;
  $_->explanation for @{ $self->{CONTENT} };
  ($format = $oldfmt) =~ s/  /~~/;
  
  $string = ')' . $self->quant;
  $explanation = $self->extra_info;

  %modes = %old;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::lookahead::explanation {
  my $self = shift;
  my $explanation =
    'look ahead to see if there is' .
    ($self->{POS} ? '' : ' not') .
    ":";
  my $string = $self->string;
  
  formline($format, $string, $explanation);

  my %old = %modes;

  my $oldfmt = $format;
  $format =~ s/\^<<(<+)/  ^$1/g;
  $format =~ s/  /~~/;
  $_->explanation for @{ $self->{CONTENT} };
  ($format = $oldfmt) =~ s/  /~~/;
  
  $string = ')' . $self->quant;
  $explanation = $self->extra_info;

  %modes = %old;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::lookbehind::explanation {
  my $self = shift;
  my $explanation =
    'look behind to see if there is' .
    ($self->{POS} ? '' : ' not') .
    ":";
  my $string = $self->string;
  
  formline($format, $string, $explanation);

  my %old = %modes;

  my $oldfmt = $format;
  $format =~ s/\^<<(<+)/  ^$1/g;
  $format =~ s/  /~~/;
  $_->explanation for @{ $self->{CONTENT} };
  ($format = $oldfmt) =~ s/  /~~/;
  
  $string = ')' . $self->quant;
  $explanation = $self->extra_info;

  %modes = %old;
  
  formline($format, $string, $explanation);
}


sub YAPE::Regex::Explain::conditional::explanation {
  my $self = shift;
  my $explanation = "if back-reference \\$self->{BACKREF} matched, then:";
  my $string = $self->string;
  
  formline($format, $string, $explanation);

  my %old = %modes;

  my $oldfmt = $format;
  $format =~ s/\^<<(<+)/  ^$1/g;
  $format =~ s/  /~~/;

  $_->explanation for @{ $self->{TRUE} };

  unless (@{ $self->{TRUE} }) {
    my $string = "";
    my $explanation = "match nothing";
    formline($format, $string, $explanation);
  }
  
  if (@{ $self->{FALSE} }) {
    my $string = "|";
    my $explanation = "OTHERWISE";
    my $oldfmt = $format;
    $format =~ s/ (\^<+)/$1 /g;
    $format =~ s/  /~~/;
    formline($format, $string, $explanation);
    ($format = $oldfmt) =~ s/  /~~/;
  }
  
  $_->explanation for @{ $self->{FALSE} };

  ($format = $oldfmt) =~ s/  /~~/;
  
  $string = ')' . $self->quant;
  $explanation = $self->extra_info;

  %modes = %old;
  
  formline($format, $string, $explanation);
}



1;

__END__

=head1 NAME

YAPE::Regex::Explain - explanation of a regular expression

=head1 SYNOPSIS

  use YAPE::Regex::Explain;
  my $exp = YAPE::Regex::Explain->new($REx)->explain;

=head1 C<YAPE> MODULES

The C<YAPE> hierarchy of modules is an attempt at a unified means of parsing
and extracting content.  It attempts to maintain a generic interface, to
promote simplicity and reusability.  The API is powerful, yet simple.  The
modules do tokenization (which can be intercepted) and build trees, so that
extraction of specific nodes is doable.

=head1 DESCRIPTION

This module merely sub-classes C<YAPE::Regex>, and produces a rather verbose
explanation of a regex, suitable for demonstration and tutorial purposes.

=head1 SUPPORT

Visit C<YAPE>'s web site at F<http://www.pobox.com/~japhy/YAPE/>.

=head1 SEE ALSO

The C<YAPE::Regex> documentation.

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut


