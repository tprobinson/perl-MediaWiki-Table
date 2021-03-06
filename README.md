# NAME

MediaWiki::Table - Generate MediaWiki table from table data

# VERSION

version 0.0.1

# SYNOPSIS

```perl
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

```
# METHODS

## new()

Creates a MediaWiki::Table item. This can accept either an array or a hash.

If it is given an array of arrays, it assumes the first row is headers, and the rest are rows:

```perl
    new MediaWiki::Table(
      ['header1','header2','header3'],
      ['data1','data2','data3'],
    );

```
If just a array, it assumes you are using a Text::Table style construction:

```perl
    new MediaWiki::Table('header1','header2','header3')
      ->load(['data1','data2','data3']);

```
If it is given a hash, it can accept multiple styles of construction, such as Text::Table::Tiny style:

```perl
    new MediaWiki::Table({
      header_row => 1,
      rows => [
        ['header1','header2','header3'],
        ['data1','data2','data3']
      ],
    });

```
Alternately, using headers:

```perl
    new MediaWiki::Table({
      headers => ['header1','header2','header3']
      rows => [['data1','data2','data3']],
    });

```
Or, for maximum object-orientation, you can return an empty object and add to it later:

```perl
    new MediaWiki::Table()
    ->headers('header1','header2','header3')
    ->rows(
      ['0','Lancelot','Blue')],
      ['1','Galahad','<strike>Blue</strike>Yellow'],
      ['2','Robin',q(''unknown'')],
      ['3','Arthur',"unknown\nbut maybe\ngreen"],
    );

```
## style

The style parameter is internally stored as a CSS::DOM::Style object, and will be returned as one.

```perl
    # returns the existing style as CSS::DOM::Style
    $tab->style();

    # replaces any existing style in the table
    $tab->style('width: 50%; height: 250px; overflow: scroll-y'); # via parse
    $tab->style(CSS::DOM::Style::parse(' text-decoration: none ')); # or via your own object

    # edits the style by using CSS::DOM::Style methods
    $tab->style()->setProperty('color' => 'green');

    # removes the style entirely
    $tab->style('');

```
# Constructor

# Methods

All data and style methods in this package have the following features:

- Supported as a constructor hash key
- Can be called with zero arguments to get the value
- Can be called with a matching-type argument to set the value
- Can be called with a falsy value (probably `''`) to delete the value

## Data Methods

- `headers`: accepts array
- `rows`: accepts array of arrays

## Style Methods

These methods modify the style of the table somehow.

- `caption`: accepts string
- `style`: accepts valid CSS style
- `class`: accepts string
- `border`: accepts number

Special information about the `style` method:

## Printing Methods

These methods return the table as a string and are interchangeable.
The table can be included into a string or compared using 'cmp' as if it were a normal string, so you don't really need to use these unless you really like Text::Table or Text::Table::Tiny.

- `stringify`
- `generate_table`
- `table`

# See Also

[Text::Table](https://metacpan.org/pod/Text::Table)

[Text::Table::Tiny](https://metacpan.org/pod/Text::Table::Tiny)

[MediaWiki::Table::Tiny](https://metacpan.org/pod/MediaWiki::Table::Tiny)

[CSS::DOM::Style](https://metacpan.org/pod/CSS::DOM::Style)

# AUTHOR

Trevor Robinson <tprobinson93@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Trevor Robinson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
