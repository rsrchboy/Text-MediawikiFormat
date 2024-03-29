#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 16;
use Test::NoWarnings;

use_ok 'Text::MediawikiFormat', as => 'wf', process_html => 0;

my $wikitext =<<WIKI;


* unordered

Final paragraph.

WIKI

my $htmltext = eval { wf ($wikitext) };

is $@, '',
   'format() should throw no warnings for text starting with newlines';

like $htmltext, qr!<li>unordered</li>!, 
     'ensure that lists followed by paragraphs are included correctly'; 

package Baz;
use Text::MediawikiFormat as => 'wf', process_html => 0;

::can_ok( 'Baz', 'wf' );

package main;

##
## make sure tag overrides work for Kake
##

$wikitext = <<WIKI;

* foo
** bar

WIKI

my %format_tags = (
	indent   => qr/^(?:\t+|\s{4,}|(?=\*+))/,
	blocks   => { unordered => qr/^\s*\*+\s*/ },
	nests    => { unordered => 1 },
);

$htmltext = wf ($wikitext, \%format_tags);

like $htmltext, qr/<li>foo<\/li>/, "first level of unordered list";
like $htmltext, qr/<li>bar<\/li>/, "nested unordered lists OK";

##
## Check that blocks not in blockorder are not fatal
##
%format_tags = (
	blocks     => {
		definition => qr/^:\s*/
	},
	definition => [ "<dl>\n", "</dl>\n", '<dt><dd>', "\n" ],
	blockorder => [ 'definition' ],
);

my $warning;
local $SIG{__WARN__} = sub { $warning = shift };
eval { wf ($wikitext, \%format_tags) };
is $@, '', 'format() should not die if a block is missing from blockorder';
like $warning, qr/No order specified/, '... warning instead';

my $foo = 'x';
$foo .= '' unless $foo =~ /x/;
my $html  = wf ('test');
is $html, "<p>test</p>\n", 'successful prior match should not whomp format()';

$wikitext =<<'WIKI';
Here is some example code:

	sub example_code
	{
		my ($foo) = @_;
		my $this = call_that $foo;
	}

Isn't it nice?
WIKI

$htmltext = wf ($wikitext, {blocks => {code => qr/^\t/}});

like $htmltext, qr!<pre>sub example_code[^<]+}\s*</pre>!m,
     'pre tags should work'; 

like $htmltext, qr!^\tmy \(\$foo\)!m, '... not removing further indents'; 

$wikitext =<<WIKI;
CamelCase
CamooseCase
NOTCAMELCASE
WIKI

$htmltext = wf ($wikitext, {}, {implicit_links => 1});

like $htmltext, qr!<a href='CamelCase'>CamelCase</a>!, 
     'parse actual CamelCase words into links'; 
like $htmltext, qr!<a href='CamooseCase'>CamooseCase</a>!, 
     '... not repeating if using link as title'; 
like $htmltext, qr!^NOTCAMELCASE!m, '... but not words in all uppercase'; 

my @processed = Text::MediawikiFormat::_nest_blocks ([]);
is @processed, 0, '_nest_blocks() should not autovivify empty blocks array';
