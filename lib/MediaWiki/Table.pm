package MediaWiki::Table;

use strict;
use warnings;

our $VERSION = '0.0.1';
$VERSION = eval $VERSION;

# Support stringification and comparison
use overload
  fallback => 1,
  # Don't stringify when only doing boolean tests, since stringification can
  # be expensive for large tables:
  bool => sub { return 1; },
  '""' => 'stringify';

use Carp;
use Params::Util 1.00 qw/_STRING _NUMBER _SCALAR _ARRAY _ARRAYLIKE _HASH _HASHLIKE _INSTANCE/;

# for the element formatting
use CSS::DOM::Style 0.16;

use List::Util 1.33 qw/any/;

sub new {
  my $class = shift;

  my $self = {
    'style' => CSS::DOM::Style::parse(q(text-align:center)),
    'border' => 1,
    'class' => 'wikitable',

    'headers' => [],

    'caption' => '',

    'rows' => [],
  };

  # Check if we're being invoked with a hashref -- OO interface
	my %options;
  if( _HASHLIKE($_[0]) )
	{ %options = %{ $_[0] }; }

  # Support being called with just an array -- Text::Table interface
  elsif( _ARRAY(\@_) )
  {
    # If it's an array of arrays, this is being called with rows directly, which is similar to MediaWiki::Table::Tiny.
    if( _ARRAYLIKE($_[0]) )
    {
      # First arrayref is headers
      $self->{'headers'} = shift @_;

      # Rest are rows
      $self->{'rows'} = [@_];
    }
    else
    {
      # Otherwise, these are just the headers
      $self->{'headers'} = \@_;
    }
  }

  # Process the options hash if we had one
  if( _HASH(\%options) )
  {
    # Direct-set most parameters
    foreach my $param (qw/headers caption rows/)
    {
      if( defined($options{$param}) )
      {
        # check that type matches
        if( ref $options{$param} ne ref $self->{$param} )
        { carp( "Parameter $param expected type ". ref $self->{$param} .", but got ". ref $options{$param} ."." ); }
        else
        { $self->{$param} = $options{$param}; }
      }
    }

    # Special parameters
    if( defined $options{'style'} )
    {
      # I don't know if I can just call $self->style?
      # Create a CSS::DOM::Style object for them if they just give a string
      if( _INSTANCE $options{'style'}, 'CSS::DOM::Style' )
      { $self->{'style'} = $options{'style'}; }
      elsif( _STRING $options{'style'} )
      { $self->{'style'} = CSS::DOM::Style::parse( $options{'style'} ); }
      else
      { carp( "Parameter style expected either a CSS::DOM::Style object or a string, but got ". ref $options{'style'} ."." ); }
    }

    if( defined $options{'header_row'} && $options{'header_row'} && scalar @{$self->{'headers'}} == 0 )
    {
      # If we're passed header_row, in a Text::Table::Tiny style, take the first row as headers
      $self->{'headers'} = shift @{ $self->{'rows'} };
    }
  }

  return bless $self, $class;
}

# Parameter setters

sub caption {
  my $self = shift;
  my $param = shift;

  # Getter
  if( ! defined $param )
  { return $self->{'caption'}; }

  # Setter - check if it's a valid value, deref if needed
  if( _SCALAR( $param ) )
  { $param = $$param; }

  if( ! _STRING( $param ) )
  { carp("Method caption only accepts a string."); }

  $self->{'caption'} = $param;

  return $self;
}

sub style {
  my $self = shift;
  my $param = shift;

  # Getter
  if( ! defined $param )
  { return $self->{'style'}; }

  # Setter
  # Create a CSS::DOM::Style object for them if they just give a string
  if( _INSTANCE $param, 'CSS::DOM::Style' )
  { $self->{'style'} = $param; }
  elsif( _STRING $param )
  { $self->{'style'} = CSS::DOM::Style::parse( $param ); }
  elsif( ! $param )
  { $self->{'style'} = undef; }
  else
  { carp( "Parameter style expected either a CSS::DOM::Style object or a string, but got ". ref $param ."." ); }

  return $self;
}

sub border {
  my $self = shift;
  my $param = shift;

  # Getter
  if( ! defined $param )
  { return $self->{'border'}; }

  # Setter - check if it's a valid value, deref if needed
  if( _SCALAR( $param ) )
  { $param = $$param; }

  if( ! defined _NUMBER( $param ) )
  {
    if( ! $param )
    { $param = undef; }
    else
    { carp("Method border only accepts a number."); }
  }

  $self->{'border'} = $param;

  return $self;
}

sub class {
  my $self = shift;
  my $param = shift;

  # Getter
  if( ! defined $param )
  { return $self->{'class'}; }

  # Setter - check if it's a valid value, deref if needed
  if( _SCALAR( $param ) )
  { $param = $$param; }

  if( ! _STRING( $param ) )
  {
    if( ! $param )
    { $param = undef; }
    else
    { carp("Method class only accepts a string."); }
  }

  $self->{'class'} = $param;

  return $self;
}

sub headers {
  my $self = shift;

  # Getter
  if( ! @_ )
  { return $self->{'headers'}; }

  # Setter
  # No dereffing or anything like that, so we don't interfere with the user's data structure.
  if( _ARRAY(\@_) )
  { $self->{'headers'} = \@_; }
  else
  { carp("Unknown object type passed to headers"); return 0; }

  return $self;
}

sub rows { return load(@_); }

# Text::Table style
sub load {
  my $self = shift;

  # Getter
  if( ! @_ )
  { return $self->{'rows'}; }

  # Setter
  # No dereffing or anything like that, so we don't interfere with the user's data structure.
  if( _ARRAY(\@_) )
  { push( @{$self->{'rows'}}, @_ ); }
  else
  { carp("Unknown object type passed to load"); return 0; }

  return $self;
}

# Text::Table::Tiny style
sub generate_table { return generate_table(@_); }

# MediaWiki::Table::Tiny style
sub table { return generate_table(@_); }

# Text::Table style
sub stringify {
  my $self = shift;

  my %f = (
    'begin' => q({|),
    'caption' => q(|+),

    'head_delim' => q(!),
    'row_delim' => q(|-),
    'col_delim' => q(|),

    'end' => q(|}),
  );

  my $table = '';
  my @line;

  # Generate table class and style
  @line = ($f{'begin'});

  foreach my $param (qw/class border/)
  {
    if( defined $self->{$param} && $self->{$param} )
    {
      push( @line, qq($param="$self->{$param}") );
    }
  }

  if( defined $self->{'style'} )
  {
    push( @line, q(style="). $self->{'style'}->cssText .q(") );
  }

  # Push in line
  $table .= join(' ', @line). "\n";

  # Generate caption
  if( defined $self->{'caption'} && $self->{'caption'} )
  {
    @line = ($f{'caption'});

    push( @line, $self->{'caption'} );

    $table .= join(' ', @line). "\n";
  }

  # Generate headers
  if( defined $self->{'headers'} && scalar @{$self->{'headers'}} > 0 )
  {
    $table .= $f{'head_delim'};

    if( any { /\n/ } @{$self->{'headers'}} )
    {
      # We can't put it all in one line if there's any newlines.
      $table .= join("\n$f{'head_delim'}", @{$self->{'headers'}} );
    }
    else
    {
      # ! one !! two !! three
      $table .= join(' '. $f{'head_delim'} . $f{'head_delim'}. ' ', @{$self->{'headers'}} );
    }

    $table .= "\n";
  }

  $table .= $f{'row_delim'}."\n";

  # Generate rows
  if( defined $self->{'rows'} && scalar @{$self->{'rows'}} > 0 )
  {
    foreach my $row ( @{$self->{'rows'}} )
    {
      $table .= $f{'col_delim'};

      if( any { /\n/ } @{$row} )
      {
        # We can't put it all in one line if there's any newlines.
        $table .= join("\n$f{'col_delim'}", @$row );
      }
      else
      {
        # | one || two || three
        $table .= join(' '. $f{'col_delim'} . $f{'col_delim'}. ' ', @$row );
      }

      $table .= "\n".$f{'row_delim'}."\n";
    }
  }

  # End the table
  $table .= $f{'end'};

  # If we're in a nested call, output a newline first. Otherwise, last.
  if( defined whowasi() && whowasi() eq __PACKAGE__.'::stringify' ) { return "\n".$table; }
  else { return $table."\n"; }

  return $table;
}

sub whoami  { ( caller(1) )[3] }
sub whowasi { ( caller(2) )[3] }

1;
# ABSTRACT: Generate MediaWiki table from table data

=head1 SYNOPSIS

  use MediaWiki::Table;
  my @headers = ('ID','Name','Favorite Color');
  my @rows = (
    ['0','Lancelot','Blue')],
    ['1','Galahad','<strike>Blue</strike>Yellow'],
    ['2','Robin',q(''unknown'')],
    ['3','Arthur',"unknown\nbut maybe\ngreen"],
  );

  my @alldata = (
    ['ID','Name','Favorite Color'],
    ['0','Lancelot','Blue')],
    ['1','Galahad','<strike>Blue</strike>Yellow'],
    ['2','Robin',q(''unknown'')],
    ['3','Arthur',"unknown\nbut maybe\ngreen"],
  );

  # Simple style
  print new MediaWiki::Table(@alldata);

  # Text::Table::Tiny style
  print new MediaWiki::Table({'header_row' => 1, 'rows' => \@alldata });

  # Text::Table style
  print new MediaWiki::Table( 'ID','Name','Favorite Color' )->load(@alldata);

  # Super OO-style
  print new MediaWiki::Table()->headers(@headers)->rows(@rows);

  # All will produce this result:
  # {| class="wikitable" border="1" style="text-align: center"
  # !ID !! Name !! Favorite Color
  # |-
  # |0 || Lancelot || Blue
  # |-
  # |1 || Galahad || <strike>Blue</strike>Yellow
  # |-
  # |2 || Robin || ''unknown''
  # |-
  # |3
  # |Arthur
  # |unknown
  # but maybe
  # green
  # |-
  # |}

  # Tables may be nested. This gives two tables next to each other, in a parent table with minimal styling.
  # When nesting tables, it's best to remove style and border of the child tables: $t->style('')->border(0)
  new MediaWiki::Table({
    'rows' => [
      [
        new MediaWiki::Table(
          ['table','on'],
          ['left','side'],
        )->style('')->border(0),
        new MediaWiki::Table(
          ['table','on'],
          ['right','side'],
        )->style('')->border(0),
      ],
    ],
  });

=head1 Constructor

=method new()

Creates a MediaWiki::Table item. This can accept either an array or a hash.

If it is given an array of arrays, it assumes the first row is headers, and the rest are rows:

  new MediaWiki::Table(
    ['header1','header2','header3'],
    ['data1','data2','data3'],
  );

If just a array, it assumes you are using a Text::Table style construction:

  new MediaWiki::Table('header1','header2','header3')
    ->load(['data1','data2','data3']);

If it is given a hash, it can accept multiple styles of construction, such as Text::Table::Tiny style:

  new MediaWiki::Table({
    header_row => 1,
    rows => [
      ['header1','header2','header3'],
      ['data1','data2','data3']
    ],
  });

Alternately, using headers:

  new MediaWiki::Table({
    headers => ['header1','header2','header3']
    rows => [['data1','data2','data3']],
  });

Or, for maximum object-orientation, you can return an empty object and add to it later:

  new MediaWiki::Table()
  ->headers('header1','header2','header3')
  ->rows(
    ['0','Lancelot','Blue')],
    ['1','Galahad','<strike>Blue</strike>Yellow'],
    ['2','Robin',q(''unknown'')],
    ['3','Arthur',"unknown\nbut maybe\ngreen"],
  );

=head1 Methods

All data and style methods in this package have the following features:

=over 4

=item * Supported as a constructor hash key

=item * Can be called with zero arguments to get the value

=item * Can be called with a matching-type argument to set the value

=item * Can be called with a falsy value (probably C<''>) to delete the value

=back

=head2 Data Methods

=over 4

=item * C<headers>: accepts array

=item * C<rows>: accepts array of arrays

=back

=head2 Style Methods

These methods modify the style of the table somehow.

=over 4

=item * C<caption>: accepts string

=item * C<style>: accepts valid CSS style

=item * C<class>: accepts string

=item * C<border>: accepts number

=back

Special information about the C<style> method:

=method style

The style parameter is internally stored as a CSS::DOM::Style object, and will be returned as one.

  # returns the existing style as CSS::DOM::Style
  $tab->style();

  # replaces any existing style in the table
  $tab->style('width: 50%; height: 250px; overflow: scroll-y'); # via parse
  $tab->style(CSS::DOM::Style::parse(' text-decoration: none ')); # or via your own object

  # edits the style by using CSS::DOM::Style methods
  $tab->style()->setProperty('color' => 'green');

  # removes the style entirely
  $tab->style('');

=head2 Printing Methods

These methods return the table as a string and are interchangeable.
The table can be included into a string or compared using 'cmp' as if it were a normal string, so you don't really need to use these unless you really like Text::Table or Text::Table::Tiny.

=over 4

=item * C<stringify>

=item * C<generate_table>

=item * C<table>

=back

=head1 See Also

L<Text::Table>

L<Text::Table::Tiny>

L<MediaWiki::Table::Tiny>

L<CSS::DOM::Style>
