#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use MediaWiki::Table;

my $simpletable = <<TABLE;
{| class="wikitable" border="1" style="text-align: center"
!h1 !! h2 !! h3
|-
|d1 || d2 || d3
|-
|d4 || d5 || d6
|-
|}
TABLE

my $captiontable = <<TABLE;
{| class="wikitable" border="1" style="text-align: center"
|+ '''TEST'''
!h1 !! h2 !! h3
|-
|d1 || d2 || d3
|-
|d4 || d5 || d6
|-
|}
TABLE

my $nestedtable = <<TABLE;
{| class="wikitable" border="1" style="text-align: center"
|-
|
{| class="wikitable"
!h1 !! h2 !! h3
|-
|d1 || d2 || d3
|-
|d7 || d8 || d9
|-
|}
|
{| class="wikitable"
!h4 !! h5 !! h6
|-
|d4 || d5 || d6
|-
|d0 || dA || dB
|-
|}
|-
|}
TABLE

my $test = new MediaWiki::Table;
ok( defined $test, 'Object Creation - Defined' );
ok( $test, 'Object Creation - Is True');
ok( $test->isa('MediaWiki::Table'), 'Object Creation - Class' );

ok( defined $test->style(), 'Object Creation - Style' );
ok( defined $test->border(), 'Object Creation - Border' );
ok( defined $test->class(), 'Object Creation - Class' );
ok( defined $test->rows(), 'Object Creation - Rows' );
ok( defined $test->headers(), 'Object Creation - Headers' );

is(
new MediaWiki::Table(
  ['h1','h2','h3'],
  ['d1','d2','d3'],
  ['d4','d5','d6']
), $simpletable,
'Array Invocation - Simple');

is(
new MediaWiki::Table(
  'h1','h2','h3',
)->load(
  ['d1','d2','d3'],
  ['d4','d5','d6']
), $simpletable,
'Array Invocation - Text::Table');

is(
new MediaWiki::Table({
  'headers' => ['h1','h2','h3'],
  'rows' => [
    ['d1','d2','d3'],
    ['d4','d5','d6'],
  ],
}), $simpletable,
'Hash Invocation - Simple');

is(
new MediaWiki::Table({
  'header_row' => 1,
  'rows' => [
    ['h1','h2','h3'],
    ['d1','d2','d3'],
    ['d4','d5','d6'],
  ],
}), $simpletable,
'Hash Invocation - Text::Table::Tiny');

is(
new MediaWiki::Table({
  'caption' => q('''TEST'''),
  'headers' => ['h1','h2','h3'],
  'rows' => [
    ['d1','d2','d3'],
    ['d4','d5','d6'],
  ],
}), $captiontable,
'Hash Invocation - Caption');

is(
new MediaWiki::Table()
->headers('h1','h2','h3')
->rows(
  ['d1','d2','d3'],
  ['d4','d5','d6'],
), $simpletable,
'Empty Invocation - Simple');

is(
new MediaWiki::Table()
->caption(q('''TEST'''))
->headers('h1','h2','h3')
->rows(
  ['d1','d2','d3'],
  ['d4','d5','d6'],
), $captiontable,
'Empty Invocation - Caption');

is(
new MediaWiki::Table({
  'rows' => [
    [
      new MediaWiki::Table(
        ['h1','h2','h3'],
        ['d1','d2','d3'],
        ['d7','d8','d9']
      )->style('')->border(0),
      new MediaWiki::Table(
        ['h4','h5','h6'],
        ['d4','d5','d6'],
        ['d0','dA','dB']
      )->style('')->border(0)

    ]
  ],
}), $nestedtable,
'Nested Tables');

# Should test getters/setters

# Testing conflicting
is(
new MediaWiki::Table({
  'caption' => q('''TEST'''),
  'headers' => ['h1','h2','h3'],
  'header_row' => 1, # This should not stomp the existing headers
  'rows' => [
    ['d1','d2','d3'],
    ['d4','d5','d6'],
  ],
}), $captiontable,
'Hash Invocation - Bad Args - Header Row with Headers');

done_testing();
