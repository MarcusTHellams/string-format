assert = require 'assert'

format = require '../src/string-format'


throws = (str, block) ->
  sep = ': '
  idx = str.indexOf(sep)
  if idx >= 0
    assert.throws block, (err) ->
      err instanceof Error and
      err.name is str.substr(0, idx) and
      err.message is str.substr(idx + sep.length)
  else
    assert.throws block, (err) ->
      err instanceof Error and
      err.name is str


describe 'String::format', ->


  it 'interpolates positional arguments', ->
    assert.strictEqual(
      '{0}, you have {1} unread message{2}'.format('Holly', 2, 's')
      'Holly, you have 2 unread messages')


  it 'throws a KeyError if there are unmatched placeholders', ->
    throws 'KeyError: "2"', -> '{0} {1} {2}'.format('x', 'y')


  it 'allows indexes to be omitted if they are entirely sequential', ->
    assert.strictEqual(
      '{}, you have {} unread message{}'.format('Holly', 2, 's')
      'Holly, you have 2 unread messages')


  it 'replaces all occurrences of a placeholder', ->
    assert.strictEqual(
      'the meaning of life is {0} ({1} x {2} is also {0})'.format(42, 6, 7)
      'the meaning of life is 42 (6 x 7 is also 42)')


  it 'does not allow explicit and implicit numbering to be intermingled', ->
    throws 'ValueError: cannot switch from implicit to explicit numbering', ->
      '{} {0}'.format('foo', 'bar')

    throws 'ValueError: cannot switch from explicit to implicit numbering', ->
      '{1} {}'.format('foo', 'bar')


  it 'treats "{{" and "}}" as "{" and "}"', ->
    assert.strictEqual '{{ {}: "{}" }}'.format('foo', 'bar'), '{ foo: "bar" }'


  it 'does not allow unmatched, unescaped curly brackets', ->
    throws 'SyntaxError: unmatched, unescaped "{" in format string', ->
      'foo { bar'.format()

    throws 'SyntaxError: unmatched, unescaped "}" in format string', ->
      'foo } bar'.format()


  it 'supports property access via dot notation', ->
    bobby = first_name: 'Bobby', last_name: 'Fischer'
    garry = first_name: 'Garry', last_name: 'Kasparov'
    assert.strictEqual(
      '{0.first_name} {0.last_name} vs. {1.first_name} {1.last_name}'.format(bobby, garry)
      'Bobby Fischer vs. Garry Kasparov')


  it 'accepts a shorthand for properties of the first positional argument', ->
    bobby = first_name: 'Bobby', last_name: 'Fischer'
    assert.strictEqual '{first_name} {last_name}'.format(bobby), 'Bobby Fischer'


  it 'invokes methods', ->
    assert.strictEqual '{0.toLowerCase}'.format('III'), 'iii'
    assert.strictEqual '{0.toUpperCase}'.format('iii'), 'III'
    assert.strictEqual '{0.getFullYear}'.format(new Date '26 Apr 1984'), '1984'
    assert.strictEqual '{pop}{pop}{pop}'.format(['one', 'two', 'three']), 'threetwoone'
    assert.strictEqual '{quip.toUpperCase}'.format(quip: -> 'Bazinga!'), 'BAZINGA!'


  String::format.transformers.s = (num) -> if num is 1 then '' else 's'


  it 'applies transformers to explicit positional arguments', ->
    text = '{0}, you have {1} unread message{1!s}'
    assert.strictEqual text.format('Steve', 1), 'Steve, you have 1 unread message'
    assert.strictEqual text.format('Holly', 2), 'Holly, you have 2 unread messages'


  it 'applies transformers to implicit positional arguments', ->
    text = 'The Cure{!s}, The Door{!s}, The Smith{!s}'
    assert.strictEqual text.format(1, 2, 3), 'The Cure, The Doors, The Smiths'


  it 'applies transformers to properties of explicit positional arguments', ->
    text = '<a href="/inbox">view message{0.length!s}</a>'
    assert.strictEqual text.format(new Array 1), '<a href="/inbox">view message</a>'
    assert.strictEqual text.format(new Array 2), '<a href="/inbox">view messages</a>'


  it 'applies transformers to properties of implicit positional arguments', ->
    text = '<a href="/inbox">view message{length!s}</a>'
    assert.strictEqual text.format(new Array 1), '<a href="/inbox">view message</a>'
    assert.strictEqual text.format(new Array 2), '<a href="/inbox">view messages</a>'


  it 'throws a ValueError if transformer name is absent', ->
    throws 'ValueError: invalid transformer name', -> '{!}'.format(123)
    throws 'ValueError: invalid transformer name', -> '{!:}'.format(123)


  it 'throws a ValueError if given a nonexistent transformer name', ->
    throws 'ValueError: unknown transformer "x"', -> '{!x}'.format(123)


  it 'asdf', ->
    throws 'SyntaxError: unused characters in format specifier', ->
      '{:ff}'.format(42)


  it 'tests:type', ->
    assert.strictEqual '{:}'.format('abc'), 'abc'
    assert.strictEqual '{:s}'.format('abc'), 'abc'

    assert.strictEqual '{:}'.format(42), '42'
    assert.strictEqual '{:c}'.format(42), '*'
    assert.strictEqual '{:d}'.format(42), '42'
    assert.strictEqual '{:b}'.format(42), '101010'
    assert.strictEqual '{:o}'.format(42), '52'
    assert.strictEqual '{:x}'.format(42), '2a'
    assert.strictEqual '{:X}'.format(42), '2A'
    assert.strictEqual '{:e}'.format(42), '4.200000e+1'
    assert.strictEqual '{:E}'.format(42), '4.200000E+1'
    assert.strictEqual '{:f}'.format(42), '42.000000'
    assert.strictEqual '{:g}'.format(42), '42'
    assert.strictEqual '{:G}'.format(42), '42'
    assert.strictEqual '{:%}'.format(42), '4200.000000%'

    assert.strictEqual '{:}'.format(3.14), '3.14'
    assert.strictEqual '{:e}'.format(3.14), '3.140000e+0'
    assert.strictEqual '{:E}'.format(3.14), '3.140000E+0'
    assert.strictEqual '{:f}'.format(3.14), '3.140000'
    assert.strictEqual '{:g}'.format(3.14), '3.14'
    assert.strictEqual '{:G}'.format(3.14), '3.14'
    assert.strictEqual '{:%}'.format(3.14), '314.000000%'

    throws 'ValueError: cannot format non-integer with format specifier "c"', ->
      '{:c}'.format(3.14)

    throws 'ValueError: cannot format non-integer with format specifier "d"', ->
      '{:d}'.format(3.14)

    throws 'ValueError: cannot format non-integer with format specifier "b"', ->
      '{:b}'.format(3.14)

    throws 'ValueError: cannot format non-integer with format specifier "o"', ->
      '{:o}'.format(3.14)

    throws 'ValueError: cannot format non-integer with format specifier "x"', ->
      '{:x}'.format(3.14)

    throws 'ValueError: cannot format non-integer with format specifier "X"', ->
      '{:X}'.format(3.14)

    assert.strictEqual '{:}'.format([1, 2, 3]), '1,2,3'


  it 'tests:align', ->
    assert.strictEqual '{:<1s}'.format('abc'),  'abc'
    assert.strictEqual '{:<8s}'.format('abc'),  'abc     '
    assert.strictEqual '{:<15s}'.format('abc'), 'abc            '

    assert.strictEqual '{:^1s}'.format('abc'),  'abc'
    assert.strictEqual '{:^8s}'.format('abc'),  '  abc   '
    assert.strictEqual '{:^15s}'.format('abc'), '      abc      '

    assert.strictEqual '{:>1s}'.format('abc'),  'abc'
    assert.strictEqual '{:>8s}'.format('abc'),  '     abc'
    assert.strictEqual '{:>15s}'.format('abc'), '            abc'

    throws 'ValueError: "=" alignment not allowed in string format specifier', ->
      '{:=}'.format('abc')
    throws 'ValueError: "=" alignment not allowed in string format specifier', ->
      '{:=s}'.format('abc')

    assert.strictEqual '{:<1c}'.format(42),   '*'
    assert.strictEqual '{:<8c}'.format(42),   '*       '
    assert.strictEqual '{:<15c}'.format(42),  '*              '

    assert.strictEqual '{:^1c}'.format(42),   '*'
    assert.strictEqual '{:^8c}'.format(42),   '   *    '
    assert.strictEqual '{:^15c}'.format(42),  '       *       '

    assert.strictEqual '{:>1c}'.format(42),   '*'
    assert.strictEqual '{:>8c}'.format(42),   '       *'
    assert.strictEqual '{:>15c}'.format(42),  '              *'

    assert.strictEqual '{:=1c}'.format(42),   '*'
    assert.strictEqual '{:=8c}'.format(42),   '       *'
    assert.strictEqual '{:=15c}'.format(42),  '              *'

    assert.strictEqual '{:<1d}'.format(-42),  '-42'
    assert.strictEqual '{:<1b}'.format(-42),  '-101010'
    assert.strictEqual '{:<1o}'.format(-42),  '-52'
    assert.strictEqual '{:<1x}'.format(-42),  '-2a'

    assert.strictEqual '{:^1d}'.format(-42),  '-42'
    assert.strictEqual '{:^1b}'.format(-42),  '-101010'
    assert.strictEqual '{:^1o}'.format(-42),  '-52'
    assert.strictEqual '{:^1x}'.format(-42),  '-2a'

    assert.strictEqual '{:>1d}'.format(-42),  '-42'
    assert.strictEqual '{:>1b}'.format(-42),  '-101010'
    assert.strictEqual '{:>1o}'.format(-42),  '-52'
    assert.strictEqual '{:>1x}'.format(-42),  '-2a'

    assert.strictEqual '{:=1d}'.format(-42),  '-42'
    assert.strictEqual '{:=1b}'.format(-42),  '-101010'
    assert.strictEqual '{:=1o}'.format(-42),  '-52'
    assert.strictEqual '{:=1x}'.format(-42),  '-2a'

    assert.strictEqual '{:<8d}'.format(-42),  '-42     '
    assert.strictEqual '{:<8b}'.format(-42),  '-101010 '
    assert.strictEqual '{:<8o}'.format(-42),  '-52     '
    assert.strictEqual '{:<8x}'.format(-42),  '-2a     '

    assert.strictEqual '{:^8d}'.format(-42),  '  -42   '
    assert.strictEqual '{:^8b}'.format(-42),  '-101010 '
    assert.strictEqual '{:^8o}'.format(-42),  '  -52   '
    assert.strictEqual '{:^8x}'.format(-42),  '  -2a   '

    assert.strictEqual '{:>8d}'.format(-42),  '     -42'
    assert.strictEqual '{:>8b}'.format(-42),  ' -101010'
    assert.strictEqual '{:>8o}'.format(-42),  '     -52'
    assert.strictEqual '{:>8x}'.format(-42),  '     -2a'

    assert.strictEqual '{:=8d}'.format(-42),  '-     42'
    assert.strictEqual '{:=8b}'.format(-42),  '- 101010'
    assert.strictEqual '{:=8o}'.format(-42),  '-     52'
    assert.strictEqual '{:=8x}'.format(-42),  '-     2a'

    assert.strictEqual '{:<15d}'.format(-42), '-42            '
    assert.strictEqual '{:<15b}'.format(-42), '-101010        '
    assert.strictEqual '{:<15o}'.format(-42), '-52            '
    assert.strictEqual '{:<15x}'.format(-42), '-2a            '

    assert.strictEqual '{:^15d}'.format(-42), '      -42      '
    assert.strictEqual '{:^15b}'.format(-42), '    -101010    '
    assert.strictEqual '{:^15o}'.format(-42), '      -52      '
    assert.strictEqual '{:^15x}'.format(-42), '      -2a      '

    assert.strictEqual '{:>15d}'.format(-42), '            -42'
    assert.strictEqual '{:>15b}'.format(-42), '        -101010'
    assert.strictEqual '{:>15o}'.format(-42), '            -52'
    assert.strictEqual '{:>15x}'.format(-42), '            -2a'

    assert.strictEqual '{:=15d}'.format(-42), '-            42'
    assert.strictEqual '{:=15b}'.format(-42), '-        101010'
    assert.strictEqual '{:=15o}'.format(-42), '-            52'
    assert.strictEqual '{:=15x}'.format(-42), '-            2a'

    assert.strictEqual '{:<1}'.format(-42),   '-42'
    assert.strictEqual '{:<1e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:<1f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:<1g}'.format(-42),  '-42'
    assert.strictEqual '{:<1%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:^1}'.format(-42),   '-42'
    assert.strictEqual '{:^1e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:^1f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:^1g}'.format(-42),  '-42'
    assert.strictEqual '{:^1%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:>1}'.format(-42),   '-42'
    assert.strictEqual '{:>1e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:>1f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:>1g}'.format(-42),  '-42'
    assert.strictEqual '{:>1%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:=1}'.format(-42),   '-42'
    assert.strictEqual '{:=1e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:=1f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:=1g}'.format(-42),  '-42'
    assert.strictEqual '{:=1%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:<8}'.format(-42),   '-42     '
    assert.strictEqual '{:<8e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:<8f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:<8g}'.format(-42),  '-42     '
    assert.strictEqual '{:<8%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:^8}'.format(-42),   '  -42   '
    assert.strictEqual '{:^8e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:^8f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:^8g}'.format(-42),  '  -42   '
    assert.strictEqual '{:^8%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:>8}'.format(-42),   '     -42'
    assert.strictEqual '{:>8e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:>8f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:>8g}'.format(-42),  '     -42'
    assert.strictEqual '{:>8%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:=8}'.format(-42),   '-     42'
    assert.strictEqual '{:=8e}'.format(-42),  '-4.200000e+1'
    assert.strictEqual '{:=8f}'.format(-42),  '-42.000000'
    assert.strictEqual '{:=8g}'.format(-42),  '-     42'
    assert.strictEqual '{:=8%}'.format(-42),  '-4200.000000%'

    assert.strictEqual '{:<15}'.format(-42),  '-42            '
    assert.strictEqual '{:<15e}'.format(-42), '-4.200000e+1   '
    assert.strictEqual '{:<15f}'.format(-42), '-42.000000     '
    assert.strictEqual '{:<15g}'.format(-42), '-42            '
    assert.strictEqual '{:<15%}'.format(-42), '-4200.000000%  '

    assert.strictEqual '{:^15}'.format(-42),  '      -42      '
    assert.strictEqual '{:^15e}'.format(-42), ' -4.200000e+1  '
    assert.strictEqual '{:^15f}'.format(-42), '  -42.000000   '
    assert.strictEqual '{:^15g}'.format(-42), '      -42      '
    assert.strictEqual '{:^15%}'.format(-42), ' -4200.000000% '

    assert.strictEqual '{:>15}'.format(-42),  '            -42'
    assert.strictEqual '{:>15e}'.format(-42), '   -4.200000e+1'
    assert.strictEqual '{:>15f}'.format(-42), '     -42.000000'
    assert.strictEqual '{:>15g}'.format(-42), '            -42'
    assert.strictEqual '{:>15%}'.format(-42), '  -4200.000000%'

    assert.strictEqual '{:=15}'.format(-42),  '-            42'
    assert.strictEqual '{:=15e}'.format(-42), '-   4.200000e+1'
    assert.strictEqual '{:=15f}'.format(-42), '-     42.000000'
    assert.strictEqual '{:=15g}'.format(-42), '-            42'
    assert.strictEqual '{:=15%}'.format(-42), '-  4200.000000%'


  it 'tests:fill+align', ->
    assert.strictEqual '{:*<1}'.format('abc'),   'abc'
    assert.strictEqual '{:*<1s}'.format('abc'),  'abc'
    assert.strictEqual '{:*<8}'.format('abc'),   'abc*****'
    assert.strictEqual '{:*<8s}'.format('abc'),  'abc*****'
    assert.strictEqual '{:*<15}'.format('abc'),  'abc************'
    assert.strictEqual '{:*<15s}'.format('abc'), 'abc************'

    assert.strictEqual '{:*^1}'.format('abc'),   'abc'
    assert.strictEqual '{:*^1s}'.format('abc'),  'abc'
    assert.strictEqual '{:*^8}'.format('abc'),   '**abc***'
    assert.strictEqual '{:*^8s}'.format('abc'),  '**abc***'
    assert.strictEqual '{:*^15}'.format('abc'),  '******abc******'
    assert.strictEqual '{:*^15s}'.format('abc'), '******abc******'

    assert.strictEqual '{:*>1}'.format('abc'),   'abc'
    assert.strictEqual '{:*>1s}'.format('abc'),  'abc'
    assert.strictEqual '{:*>8}'.format('abc'),   '*****abc'
    assert.strictEqual '{:*>8s}'.format('abc'),  '*****abc'
    assert.strictEqual '{:*>15}'.format('abc'),  '************abc'
    assert.strictEqual '{:*>15s}'.format('abc'), '************abc'

    assert.strictEqual '{:-<15c}'.format(42), '*--------------'
    assert.strictEqual '{:-^15c}'.format(42), '-------*-------'
    assert.strictEqual '{:->15c}'.format(42), '--------------*'
    assert.strictEqual '{:-=15c}'.format(42), '--------------*'

    assert.strictEqual '{:*<15d}'.format(-42), '-42************'
    assert.strictEqual '{:*<15b}'.format(-42), '-101010********'
    assert.strictEqual '{:*<15o}'.format(-42), '-52************'
    assert.strictEqual '{:*<15x}'.format(-42), '-2a************'

    assert.strictEqual '{:*^15d}'.format(-42), '******-42******'
    assert.strictEqual '{:*^15b}'.format(-42), '****-101010****'
    assert.strictEqual '{:*^15o}'.format(-42), '******-52******'
    assert.strictEqual '{:*^15x}'.format(-42), '******-2a******'

    assert.strictEqual '{:*>15d}'.format(-42), '************-42'
    assert.strictEqual '{:*>15b}'.format(-42), '********-101010'
    assert.strictEqual '{:*>15o}'.format(-42), '************-52'
    assert.strictEqual '{:*>15x}'.format(-42), '************-2a'

    assert.strictEqual '{:0=15d}'.format(-42), '-00000000000042'
    assert.strictEqual '{:0=15b}'.format(-42), '-00000000101010'
    assert.strictEqual '{:0=15o}'.format(-42), '-00000000000052'
    assert.strictEqual '{:0=15x}'.format(-42), '-0000000000002a'

    assert.strictEqual '{:*<15}'.format(-42),  '-42************'
    assert.strictEqual '{:*<15e}'.format(-42), '-4.200000e+1***'
    assert.strictEqual '{:*<15E}'.format(-42), '-4.200000E+1***'
    assert.strictEqual '{:*<15f}'.format(-42), '-42.000000*****'
    assert.strictEqual '{:*<15g}'.format(-42), '-42************'
    assert.strictEqual '{:*<15G}'.format(-42), '-42************'
    assert.strictEqual '{:*<15%}'.format(-42), '-4200.000000%**'

    assert.strictEqual '{:*^15}'.format(-42),  '******-42******'
    assert.strictEqual '{:*^15e}'.format(-42), '*-4.200000e+1**'
    assert.strictEqual '{:*^15E}'.format(-42), '*-4.200000E+1**'
    assert.strictEqual '{:*^15f}'.format(-42), '**-42.000000***'
    assert.strictEqual '{:*^15g}'.format(-42), '******-42******'
    assert.strictEqual '{:*^15G}'.format(-42), '******-42******'
    assert.strictEqual '{:*^15%}'.format(-42), '*-4200.000000%*'

    assert.strictEqual '{:*>15}'.format(-42),  '************-42'
    assert.strictEqual '{:*>15e}'.format(-42), '***-4.200000e+1'
    assert.strictEqual '{:*>15E}'.format(-42), '***-4.200000E+1'
    assert.strictEqual '{:*>15f}'.format(-42), '*****-42.000000'
    assert.strictEqual '{:*>15g}'.format(-42), '************-42'
    assert.strictEqual '{:*>15G}'.format(-42), '************-42'
    assert.strictEqual '{:*>15%}'.format(-42), '**-4200.000000%'

    assert.strictEqual '{:0=15}'.format(-42),  '-00000000000042'
    assert.strictEqual '{:0=15e}'.format(-42), '-0004.200000e+1'
    assert.strictEqual '{:0=15E}'.format(-42), '-0004.200000E+1'
    assert.strictEqual '{:0=15f}'.format(-42), '-0000042.000000'
    assert.strictEqual '{:0=15g}'.format(-42), '-00000000000042'
    assert.strictEqual '{:0=15G}'.format(-42), '-00000000000042'
    assert.strictEqual '{:0=15%}'.format(-42), '-004200.000000%'


  it 'tests:sign', ->
    throws 'ValueError: sign not allowed in string format specifier', ->
      '{:+}'.format('abc')
    throws 'ValueError: sign not allowed in string format specifier', ->
      '{:+s}'.format('abc')

    throws 'ValueError: sign not allowed with format specifier "c"', ->
      '{:+c}'.format(42)

    assert.strictEqual '{:-d}'.format(+42),  '42'
    assert.strictEqual '{:-d}'.format(-42), '-42'
    assert.strictEqual '{: d}'.format(+42), ' 42'
    assert.strictEqual '{: d}'.format(-42), '-42'
    assert.strictEqual '{:+d}'.format(+42), '+42'
    assert.strictEqual '{:+d}'.format(-42), '-42'

    assert.strictEqual '{:-b}'.format(+42),  '101010'
    assert.strictEqual '{:-b}'.format(-42), '-101010'
    assert.strictEqual '{: b}'.format(+42), ' 101010'
    assert.strictEqual '{: b}'.format(-42), '-101010'
    assert.strictEqual '{:+b}'.format(+42), '+101010'
    assert.strictEqual '{:+b}'.format(-42), '-101010'

    assert.strictEqual '{:-o}'.format(+42),  '52'
    assert.strictEqual '{:-o}'.format(-42), '-52'
    assert.strictEqual '{: o}'.format(+42), ' 52'
    assert.strictEqual '{: o}'.format(-42), '-52'
    assert.strictEqual '{:+o}'.format(+42), '+52'
    assert.strictEqual '{:+o}'.format(-42), '-52'

    assert.strictEqual '{:-x}'.format(+42),  '2a'
    assert.strictEqual '{:-x}'.format(-42), '-2a'
    assert.strictEqual '{: x}'.format(+42), ' 2a'
    assert.strictEqual '{: x}'.format(-42), '-2a'
    assert.strictEqual '{:+x}'.format(+42), '+2a'
    assert.strictEqual '{:+x}'.format(-42), '-2a'

    assert.strictEqual '{:-}'.format(+42),   '42'
    assert.strictEqual '{:-}'.format(-42),  '-42'
    assert.strictEqual '{: }'.format(+42),  ' 42'
    assert.strictEqual '{: }'.format(-42),  '-42'
    assert.strictEqual '{:+}'.format(+42),  '+42'
    assert.strictEqual '{:+}'.format(-42),  '-42'

    assert.strictEqual '{:-e}'.format(+42),  '4.200000e+1'
    assert.strictEqual '{:-e}'.format(-42), '-4.200000e+1'
    assert.strictEqual '{: e}'.format(+42), ' 4.200000e+1'
    assert.strictEqual '{: e}'.format(-42), '-4.200000e+1'
    assert.strictEqual '{:+e}'.format(+42), '+4.200000e+1'
    assert.strictEqual '{:+e}'.format(-42), '-4.200000e+1'

    assert.strictEqual '{:-f}'.format(+42),  '42.000000'
    assert.strictEqual '{:-f}'.format(-42), '-42.000000'
    assert.strictEqual '{: f}'.format(+42), ' 42.000000'
    assert.strictEqual '{: f}'.format(-42), '-42.000000'
    assert.strictEqual '{:+f}'.format(+42), '+42.000000'
    assert.strictEqual '{:+f}'.format(-42), '-42.000000'

    assert.strictEqual '{:-g}'.format(+42),  '42'
    assert.strictEqual '{:-g}'.format(-42), '-42'
    assert.strictEqual '{: g}'.format(+42), ' 42'
    assert.strictEqual '{: g}'.format(-42), '-42'
    assert.strictEqual '{:+g}'.format(+42), '+42'
    assert.strictEqual '{:+g}'.format(-42), '-42'

    assert.strictEqual '{:-%}'.format(+42),  '4200.000000%'
    assert.strictEqual '{:-%}'.format(-42), '-4200.000000%'
    assert.strictEqual '{: %}'.format(+42), ' 4200.000000%'
    assert.strictEqual '{: %}'.format(-42), '-4200.000000%'
    assert.strictEqual '{:+%}'.format(+42), '+4200.000000%'
    assert.strictEqual '{:+%}'.format(-42), '-4200.000000%'


  it 'tests:#', ->
    throws 'ValueError: alternate form (#) not allowed in string format specifier', ->
      '{:#}'.format('abc')
    throws 'ValueError: alternate form (#) not allowed in string format specifier', ->
      '{:#s}'.format('abc')

    assert.strictEqual '{:#c}'.format(42), '*'
    assert.strictEqual '{:#d}'.format(42), '42'
    assert.strictEqual '{:#b}'.format(42), '0b101010'
    assert.strictEqual '{:#o}'.format(42), '0o52'
    assert.strictEqual '{:#x}'.format(42), '0x2a'
    assert.strictEqual '{:#X}'.format(42), '0X2A'

    assert.strictEqual '{:#}'.format(42),  '42'
    assert.strictEqual '{:#e}'.format(42), '4.200000e+1'
    assert.strictEqual '{:#E}'.format(42), '4.200000E+1'
    assert.strictEqual '{:#f}'.format(42), '42.000000'
    assert.strictEqual '{:#g}'.format(42), '42.0000'
    assert.strictEqual '{:#G}'.format(42), '42.0000'
    assert.strictEqual '{:#%}'.format(42), '4200.000000%'


  it 'tests:0', ->
    throws 'ValueError: "=" alignment not allowed in string format specifier', ->
      '{:0}'.format('abc')
    throws 'ValueError: "=" alignment not allowed in string format specifier', ->
      '{:0s}'.format('abc')

    assert.strictEqual '{:0c}'.format(42),  '*'
    assert.strictEqual '{:0d}'.format(-42), '-42'
    assert.strictEqual '{:0b}'.format(-42), '-101010'
    assert.strictEqual '{:0o}'.format(-42), '-52'
    assert.strictEqual '{:0x}'.format(-42), '-2a'
    assert.strictEqual '{:0X}'.format(-42), '-2A'

    assert.strictEqual '{:0}'.format(-42),  '-42'
    assert.strictEqual '{:0e}'.format(-42), '-4.200000e+1'
    assert.strictEqual '{:0E}'.format(-42), '-4.200000E+1'
    assert.strictEqual '{:0f}'.format(-42), '-42.000000'
    assert.strictEqual '{:0g}'.format(-42), '-42'
    assert.strictEqual '{:0G}'.format(-42), '-42'
    assert.strictEqual '{:0%}'.format(-42), '-4200.000000%'

    assert.strictEqual '{:08c}'.format(42),  '0000000*'
    assert.strictEqual '{:08d}'.format(-42), '-0000042'
    assert.strictEqual '{:08b}'.format(-42), '-0101010'
    assert.strictEqual '{:08o}'.format(-42), '-0000052'
    assert.strictEqual '{:08x}'.format(-42), '-000002a'
    assert.strictEqual '{:08X}'.format(-42), '-000002A'

    assert.strictEqual '{:08}'.format(-42),  '-0000042'
    assert.strictEqual '{:08e}'.format(-42), '-4.200000e+1'
    assert.strictEqual '{:08E}'.format(-42), '-4.200000E+1'
    assert.strictEqual '{:08f}'.format(-42), '-42.000000'
    assert.strictEqual '{:08g}'.format(-42), '-0000042'
    assert.strictEqual '{:08G}'.format(-42), '-0000042'
    assert.strictEqual '{:08%}'.format(-42), '-4200.000000%'

    assert.strictEqual '{:015c}'.format(42),  '00000000000000*'
    assert.strictEqual '{:015d}'.format(-42), '-00000000000042'
    assert.strictEqual '{:015b}'.format(-42), '-00000000101010'
    assert.strictEqual '{:015o}'.format(-42), '-00000000000052'
    assert.strictEqual '{:015x}'.format(-42), '-0000000000002a'
    assert.strictEqual '{:015X}'.format(-42), '-0000000000002A'

    assert.strictEqual '{:015}'.format(-42),  '-00000000000042'
    assert.strictEqual '{:015e}'.format(-42), '-0004.200000e+1'
    assert.strictEqual '{:015E}'.format(-42), '-0004.200000E+1'
    assert.strictEqual '{:015f}'.format(-42), '-0000042.000000'
    assert.strictEqual '{:015g}'.format(-42), '-00000000000042'
    assert.strictEqual '{:015G}'.format(-42), '-00000000000042'
    assert.strictEqual '{:015%}'.format(-42), '-004200.000000%'


  it 'tests:width', ->
    assert.strictEqual '{:1}'.format('abc'),   'abc'
    assert.strictEqual '{:1s}'.format('abc'),  'abc'
    assert.strictEqual '{:8}'.format('abc'),   'abc     '
    assert.strictEqual '{:8s}'.format('abc'),  'abc     '
    assert.strictEqual '{:15}'.format('abc'),  'abc            '
    assert.strictEqual '{:15s}'.format('abc'), 'abc            '

    assert.strictEqual '{:1c}'.format(42),  '*'
    assert.strictEqual '{:1d}'.format(42),  '42'
    assert.strictEqual '{:1b}'.format(42),  '101010'
    assert.strictEqual '{:1o}'.format(42),  '52'
    assert.strictEqual '{:1x}'.format(42),  '2a'
    assert.strictEqual '{:1X}'.format(42),  '2A'

    assert.strictEqual '{:1}'.format(42),   '42'
    assert.strictEqual '{:1e}'.format(42),  '4.200000e+1'
    assert.strictEqual '{:1E}'.format(42),  '4.200000E+1'
    assert.strictEqual '{:1f}'.format(42),  '42.000000'
    assert.strictEqual '{:1g}'.format(42),  '42'
    assert.strictEqual '{:1G}'.format(42),  '42'
    assert.strictEqual '{:1%}'.format(42),  '4200.000000%'

    assert.strictEqual '{:8c}'.format(42),  '       *'
    assert.strictEqual '{:8d}'.format(42),  '      42'
    assert.strictEqual '{:8b}'.format(42),  '  101010'
    assert.strictEqual '{:8o}'.format(42),  '      52'
    assert.strictEqual '{:8x}'.format(42),  '      2a'
    assert.strictEqual '{:8X}'.format(42),  '      2A'

    assert.strictEqual '{:8}'.format(42),   '      42'
    assert.strictEqual '{:8e}'.format(42),  '4.200000e+1'
    assert.strictEqual '{:8E}'.format(42),  '4.200000E+1'
    assert.strictEqual '{:8f}'.format(42),  '42.000000'
    assert.strictEqual '{:8g}'.format(42),  '      42'
    assert.strictEqual '{:8G}'.format(42),  '      42'
    assert.strictEqual '{:8%}'.format(42),  '4200.000000%'

    assert.strictEqual '{:15c}'.format(42), '              *'
    assert.strictEqual '{:15d}'.format(42), '             42'
    assert.strictEqual '{:15b}'.format(42), '         101010'
    assert.strictEqual '{:15o}'.format(42), '             52'
    assert.strictEqual '{:15x}'.format(42), '             2a'
    assert.strictEqual '{:15X}'.format(42), '             2A'

    assert.strictEqual '{:15}'.format(42),  '             42'
    assert.strictEqual '{:15e}'.format(42), '    4.200000e+1'
    assert.strictEqual '{:15E}'.format(42), '    4.200000E+1'
    assert.strictEqual '{:15f}'.format(42), '      42.000000'
    assert.strictEqual '{:15g}'.format(42), '             42'
    assert.strictEqual '{:15G}'.format(42), '             42'
    assert.strictEqual '{:15%}'.format(42), '   4200.000000%'


  it 'tests:,', ->
    throws 'ValueError: cannot specify "," with "s"', -> '{:,}'.format('abc')
    throws 'ValueError: cannot specify "," with "s"', -> '{:,s}'.format('abc')
    throws 'ValueError: cannot specify "," with "c"', -> '{:,c}'.format(42)
    throws 'ValueError: cannot specify "," with "b"', -> '{:,b}'.format(42)
    throws 'ValueError: cannot specify "," with "o"', -> '{:,o}'.format(42)
    throws 'ValueError: cannot specify "," with "x"', -> '{:,x}'.format(42)
    throws 'ValueError: cannot specify "," with "X"', -> '{:,X}'.format(42)

    assert.strictEqual '{:,}'.format(1234567.89),  '1,234,567.89'
    assert.strictEqual '{:,d}'.format(1234567),    '1,234,567'
    assert.strictEqual '{:,e}'.format(1234567.89), '1.234568e+6'
    assert.strictEqual '{:,E}'.format(1234567.89), '1.234568E+6'
    assert.strictEqual '{:,f}'.format(1234567.89), '1,234,567.890000'
    assert.strictEqual '{:,g}'.format(1234567.89), '1.23457e+6'
    assert.strictEqual '{:,G}'.format(1234567.89), '1.23457E+6'
    assert.strictEqual '{:,%}'.format(1234567.89), '123,456,789.000000%'


  it 'tests:precision', ->
    assert.strictEqual '{:.0}'.format('abc'), ''
    assert.strictEqual '{:.1}'.format('abc'), 'a'
    assert.strictEqual '{:.2}'.format('abc'), 'ab'
    assert.strictEqual '{:.3}'.format('abc'), 'abc'
    assert.strictEqual '{:.4}'.format('abc'), 'abc'

    assert.strictEqual '{:.0s}'.format('abc'), ''
    assert.strictEqual '{:.1s}'.format('abc'), 'a'
    assert.strictEqual '{:.2s}'.format('abc'), 'ab'
    assert.strictEqual '{:.3s}'.format('abc'), 'abc'
    assert.strictEqual '{:.4s}'.format('abc'), 'abc'

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4c}'.format(42)

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4d}'.format(42)

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4b}'.format(42)

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4o}'.format(42)

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4x}'.format(42)

    throws 'ValueError: precision not allowed in integer format specifier', ->
      '{:.4X}'.format(42)

    assert.strictEqual '{:.0}'.format(3.14), '3'
    assert.strictEqual '{:.1}'.format(3.14), '3'
    assert.strictEqual '{:.2}'.format(3.14), '3.1'
    assert.strictEqual '{:.3}'.format(3.14), '3.14'
    assert.strictEqual '{:.4}'.format(3.14), '3.14'

    assert.strictEqual '{:.0e}'.format(3.14), '3e+0'
    assert.strictEqual '{:.1e}'.format(3.14), '3.1e+0'
    assert.strictEqual '{:.2e}'.format(3.14), '3.14e+0'
    assert.strictEqual '{:.3e}'.format(3.14), '3.140e+0'
    assert.strictEqual '{:.4e}'.format(3.14), '3.1400e+0'

    assert.strictEqual '{:.0E}'.format(3.14), '3E+0'
    assert.strictEqual '{:.1E}'.format(3.14), '3.1E+0'
    assert.strictEqual '{:.2E}'.format(3.14), '3.14E+0'
    assert.strictEqual '{:.3E}'.format(3.14), '3.140E+0'
    assert.strictEqual '{:.4E}'.format(3.14), '3.1400E+0'

    assert.strictEqual '{:.0f}'.format(3.14), '3'
    assert.strictEqual '{:.1f}'.format(3.14), '3.1'
    assert.strictEqual '{:.2f}'.format(3.14), '3.14'
    assert.strictEqual '{:.3f}'.format(3.14), '3.140'
    assert.strictEqual '{:.4f}'.format(3.14), '3.1400'

    assert.strictEqual '{:.0g}'.format(3.14), '3'
    assert.strictEqual '{:.1g}'.format(3.14), '3'
    assert.strictEqual '{:.2g}'.format(3.14), '3.1'
    assert.strictEqual '{:.3g}'.format(3.14), '3.14'
    assert.strictEqual '{:.4g}'.format(3.14), '3.14'

    assert.strictEqual '{:.0G}'.format(3.14), '3'
    assert.strictEqual '{:.1G}'.format(3.14), '3'
    assert.strictEqual '{:.2G}'.format(3.14), '3.1'
    assert.strictEqual '{:.3G}'.format(3.14), '3.14'
    assert.strictEqual '{:.4G}'.format(3.14), '3.14'

    throws 'SyntaxError: format specifier missing precision', ->
      '{:.f}'.format(3.14)


  it 'tests:(fill AND) align AND sign AND #', ->
    assert.strictEqual '{:<+#o}'.format(42),  '+0o52'
    assert.strictEqual '{:*<+#o}'.format(42), '+0o52'


  it 'tests:(fill AND) align AND sign AND # AND width', ->
    assert.strictEqual '{:<+#8o}'.format(42),  '+0o52   '
    assert.strictEqual '{:>+#8o}'.format(42),  '   +0o52'
    assert.strictEqual '{:*<+#8o}'.format(42), '+0o52***'
    assert.strictEqual '{:*>+#8o}'.format(42), '***+0o52'


  it 'tests:(fill AND) align AND sign AND 0', ->
    assert.strictEqual '{:<+0}'.format(42),  '+42'
    assert.strictEqual '{:*<+0}'.format(42), '+42'


  it 'tests:(fill AND) align AND sign AND 0 AND width', ->
    assert.strictEqual '{:<+08}'.format(42),  '+4200000'
    assert.strictEqual '{:>+08}'.format(42),  '00000+42'
    assert.strictEqual '{:*<+08}'.format(42), '+42*****'
    assert.strictEqual '{:*>+08}'.format(42), '*****+42'


  it 'tests:(fill AND) align AND sign AND width', ->
    assert.strictEqual '{:<+8}'.format(42),  '+42     '
    assert.strictEqual '{:>+8}'.format(42),  '     +42'
    assert.strictEqual '{:*<+8}'.format(42), '+42*****'
    assert.strictEqual '{:*>+8}'.format(42), '*****+42'


  it 'tests:(fill AND) align AND sign AND width AND precision', ->
    assert.strictEqual '{:<+8.2f}'.format(42),  '+42.00  '
    assert.strictEqual '{:>+8.2f}'.format(42),  '  +42.00'
    assert.strictEqual '{:*<+8.2f}'.format(42), '+42.00**'
    assert.strictEqual '{:*>+8.2f}'.format(42), '**+42.00'


  it 'tests:(fill AND) align AND sign AND ,', ->
    assert.strictEqual '{:<+,}'.format(4200),  '+4,200'
    assert.strictEqual '{:*<+,}'.format(4200), '+4,200'


  it 'tests:(fill AND) align AND sign AND precision', ->
    assert.strictEqual '{:<+.2f}'.format(42),  '+42.00'
    assert.strictEqual '{:*<+.2f}'.format(42), '+42.00'


  it 'tests:(fill AND) align AND # AND 0 AND width', ->
    assert.strictEqual '{:<#08o}'.format(42),  '0o520000'
    assert.strictEqual '{:>#08o}'.format(42),  '00000o52'
    assert.strictEqual '{:*<#08o}'.format(42), '0o52****'
    assert.strictEqual '{:*>#08o}'.format(42), '****0o52'


  it 'tests:(fill AND) align AND # AND ,', ->
    assert.strictEqual '{:<#,.0f}'.format(4200),  '4,200.'
    assert.strictEqual '{:*<#,.0f}'.format(4200), '4,200.'


  it 'tests:(fill AND) align AND # AND width', ->
    assert.strictEqual '{:<#8o}'.format(42),  '0o52    '
    assert.strictEqual '{:>#8o}'.format(42),  '    0o52'
    assert.strictEqual '{:*<#8o}'.format(42), '0o52****'
    assert.strictEqual '{:*>#8o}'.format(42), '****0o52'


  it 'tests:(fill AND) align AND # AND width AND ,', ->
    assert.strictEqual '{:<#8,}'.format(4200),  '4,200   '
    assert.strictEqual '{:>#8,}'.format(4200),  '   4,200'
    assert.strictEqual '{:*<#8,}'.format(4200), '4,200***'
    assert.strictEqual '{:*>#8,}'.format(4200), '***4,200'


  it 'tests:(fill AND) align AND # AND width AND precision', ->
    assert.strictEqual '{:<#8.0f}'.format(42),  '42.     '
    assert.strictEqual '{:>#8.0f}'.format(42),  '     42.'
    assert.strictEqual '{:*<#8.0f}'.format(42), '42.*****'
    assert.strictEqual '{:*>#8.0f}'.format(42), '*****42.'


  it 'tests:(fill AND) align AND # AND precision', ->
    assert.strictEqual '{:<#.2f}'.format(42),  '42.00'
    assert.strictEqual '{:*<#.2f}'.format(42), '42.00'


  it 'tests:(fill AND) align AND 0 AND width', ->
    assert.strictEqual '{:<08}'.format(-42),  '-4200000'
    assert.strictEqual '{:>08}'.format(-42),  '00000-42'
    assert.strictEqual '{:*<08}'.format(-42), '-42*****'
    assert.strictEqual '{:*>08}'.format(-42), '*****-42'


  it 'tests:(fill AND) align AND 0 AND width AND ,', ->
    assert.strictEqual '{:<08,}'.format(4200),  '4,200000'
    assert.strictEqual '{:^08,}'.format(4200),  '04,20000'
    assert.strictEqual '{:>08,}'.format(4200),  '0004,200'
    assert.strictEqual '{:=08,}'.format(4200), '0,004,200'
    assert.strictEqual '{:*<08,}'.format(4200), '4,200***'
    assert.strictEqual '{:*^08,}'.format(4200), '*4,200**'
    assert.strictEqual '{:*>08,}'.format(4200), '***4,200'
    assert.strictEqual '{:*=08,}'.format(4200), '***4,200'


  it 'tests:(fill AND) align AND 0 AND width AND precision', ->
    assert.strictEqual '{:<08.2f}'.format(-42),  '-42.0000'
    assert.strictEqual '{:^08.2f}'.format(-42),  '0-42.000'
    assert.strictEqual '{:>08.2f}'.format(-42),  '00-42.00'
    assert.strictEqual '{:=08.2f}'.format(-42),  '-0042.00'
    assert.strictEqual '{:*<08.2f}'.format(-42), '-42.00**'
    assert.strictEqual '{:*^08.2f}'.format(-42), '*-42.00*'
    assert.strictEqual '{:*>08.2f}'.format(-42), '**-42.00'
    assert.strictEqual '{:*=08.2f}'.format(-42), '-**42.00'


  it 'tests:(fill AND) align AND 0 AND ,', ->
    assert.strictEqual '{:<0,}'.format(4200),  '4,200'
    assert.strictEqual '{:*<0,}'.format(4200), '4,200'


  it 'tests:(fill AND) align AND 0 AND precision', ->
    assert.strictEqual '{:<0.2f}'.format(42),  '42.00'
    assert.strictEqual '{:*<0.2f}'.format(42), '42.00'


  it 'tests:(fill AND) align AND width AND ,', ->
    assert.strictEqual '{:<8,}'.format(-4200),   '-4,200  '
    assert.strictEqual '{:>8,}'.format(-4200),   '  -4,200'
    assert.strictEqual '{:*<8,}'.format(-4200),  '-4,200**'
    assert.strictEqual '{:*>8,}'.format(-4200),  '**-4,200'
    assert.strictEqual '{:0=8,}'.format(-4200),  '-004,200'
    assert.strictEqual '{:0=8,}'.format(+4200), '0,004,200'


  it 'tests:(fill AND) align AND width AND , AND precision', ->
    assert.strictEqual '{:<15,.2f}'.format(-4200000),  '-4,200,000.00  '
    assert.strictEqual '{:^15,.2f}'.format(-4200000),  ' -4,200,000.00 '
    assert.strictEqual '{:>15,.2f}'.format(-4200000),  '  -4,200,000.00'
    assert.strictEqual '{:=15,.2f}'.format(-4200000),  '-  4,200,000.00'
    assert.strictEqual '{:*<15,.2f}'.format(-4200000), '-4,200,000.00**'
    assert.strictEqual '{:*^15,.2f}'.format(-4200000), '*-4,200,000.00*'
    assert.strictEqual '{:*>15,.2f}'.format(-4200000), '**-4,200,000.00'
    assert.strictEqual '{:*=15,.2f}'.format(-4200000), '-**4,200,000.00'


  it 'tests:(fill AND) align AND width AND precision', ->
    assert.strictEqual '{:<8.2f}'.format(42),  '42.00   '
    assert.strictEqual '{:>8.2f}'.format(42),  '   42.00'
    assert.strictEqual '{:*<8.2f}'.format(42), '42.00***'
    assert.strictEqual '{:*>8.2f}'.format(42), '***42.00'


  it 'tests:(fill AND) align AND , AND precision', ->
    assert.strictEqual '{:<,.2f}'.format(4200),  '4,200.00'
    assert.strictEqual '{:*<,.2f}'.format(4200), '4,200.00'


  it 'tests:sign AND # AND 0', ->
    assert.strictEqual '{:+#0o}'.format(42), '+0o52'


  it 'tests:sign AND # AND width', ->
    assert.strictEqual '{:+#8o}'.format(42), '   +0o52'


  it 'tests:sign AND # AND ,', ->
    assert.strictEqual '{:+#,.0f}'.format(4200), '+4,200.'


  it 'tests:sign AND # AND precision', ->
    assert.strictEqual '{:+#.3g}'.format(4200), '+4.20e+3'


  it 'tests:sign AND 0 AND width', ->
    assert.strictEqual '{:+08}'.format(42), '+0000042'


  it 'tests:sign AND 0 AND ,', ->
    assert.strictEqual '{:+08,}'.format(4200), '+004,200'


  it 'tests:sign AND 0 AND precision', ->
    assert.strictEqual '{:+08.2f}'.format(42), '+0042.00'


  it 'tests:sign AND width AND ,', ->
    assert.strictEqual '{:+8,}'.format(4200), '  +4,200'


  it 'tests:sign AND width AND precision', ->
    assert.strictEqual '{:+8.2f}'.format(42), '  +42.00'


  it 'tests:sign AND , AND precision', ->
    assert.strictEqual '{:+,.2f}'.format(4200), '+4,200.00'


  it 'tests:# AND 0 AND width', ->
    assert.strictEqual '{:#08o}'.format(42), '0o000052'


  it 'tests:# AND 0 AND ,', ->
    assert.strictEqual '{:#08,.0f}'.format(4200), '004,200.'


  it 'tests:# AND 0 AND precision', ->
    assert.strictEqual '{:#08.3g}'.format(4200), '04.20e+3'


  it 'tests:# AND width AND ,', ->
    assert.strictEqual '{:#8,}'.format(4200), '   4,200'


  it 'tests:# AND width AND precision', ->
    assert.strictEqual '{:#8.3g}'.format(4200), ' 4.20e+3'


  it 'tests:# AND , AND precision', ->
    assert.strictEqual '{:#,.0f}'.format(4200), '4,200.'


  it 'tests:# AND precision', ->
    assert.strictEqual '{:#.0f}'.format(42), '42.'
    assert.strictEqual '{:#.0e}'.format(42), '4.e+1'
    assert.strictEqual '{:#.0g}'.format(42), '4.e+1'


  it 'tests:0 AND width AND ,', ->
    assert.strictEqual '{:08,}'.format(4200), '0,004,200'


  it 'tests:0 AND width AND precision', ->
    assert.strictEqual '{:08.2f}'.format(42), '00042.00'


  it 'tests:0 AND , AND precision', ->
    assert.strictEqual '{:08,.2f}'.format(42), '0,042.00'


  it 'tests:width AND , AND precision', ->
    assert.strictEqual '{:15,.2f}'.format(4200000), '   4,200,000.00'


  it 'asdf', ->
    assert.strictEqual '{0.@#$.%^&}'.format({'@#$': {'%^&': 42}}), '42'


  it 'asdf', ->
    String::format.transformers['@#$'] = -> 'xyz'
    assert.strictEqual '{!@#$}'.format('abc'), 'xyz'
    delete String::format.transformers['@#$']


  it 'asdf', ->
    assert.strictEqual '{:d}'.format(0),         '0'
    assert.strictEqual '{:d}'.format(-0),        '-0'
    assert.strictEqual '{:d}'.format(Infinity),  'Infinity'
    assert.strictEqual '{:d}'.format(-Infinity), '-Infinity'
    assert.strictEqual '{:d}'.format(NaN),       'NaN'

    assert.strictEqual '{}'.format(0),           '0'
    assert.strictEqual '{}'.format(-0),          '-0'
    assert.strictEqual '{}'.format(Infinity),    'Infinity'
    assert.strictEqual '{}'.format(-Infinity),   '-Infinity'
    assert.strictEqual '{}'.format(NaN),         'NaN'

    assert.strictEqual '{:f}'.format(0),         '0.000000'
    assert.strictEqual '{:f}'.format(-0),        '-0.000000'
    assert.strictEqual '{:f}'.format(Infinity),  'Infinity'
    assert.strictEqual '{:f}'.format(-Infinity), '-Infinity'
    assert.strictEqual '{:f}'.format(NaN),       'NaN'


  it 'allows "," to be used as a thousands separator', ->
    assert.strictEqual '{:,}'.format(42),             '42'
    assert.strictEqual '{:,}'.format(420),           '420'
    assert.strictEqual '{:,}'.format(4200),        '4,200'
    assert.strictEqual '{:,}'.format(42000),      '42,000'
    assert.strictEqual '{:,}'.format(420000),    '420,000'
    assert.strictEqual '{:,}'.format(4200000), '4,200,000'

    assert.strictEqual '{:00,}'.format(42),           '42'
    assert.strictEqual '{:01,}'.format(42),           '42'
    assert.strictEqual '{:02,}'.format(42),           '42'
    assert.strictEqual '{:03,}'.format(42),          '042'
    assert.strictEqual '{:04,}'.format(42),        '0,042'
    assert.strictEqual '{:05,}'.format(42),        '0,042'
    assert.strictEqual '{:06,}'.format(42),       '00,042'
    assert.strictEqual '{:07,}'.format(42),      '000,042'
    assert.strictEqual '{:08,}'.format(42),    '0,000,042'
    assert.strictEqual '{:09,}'.format(42),    '0,000,042'
    assert.strictEqual '{:010,}'.format(42),  '00,000,042'


  it 'allows non-string, non-number arguments', ->
    throws 'ValueError: non-empty format string for Array object', ->
      '{:,}'.format([1, 2, 3])

    throws 'ValueError: non-empty format string for Array object', ->
      '{:z}'.format([1, 2, 3])


  it 'throws if a number is passed to a string formatter', ->
    throws 'ValueError: unknown format code "s" for Number object', ->
      '{:s}'.format(42)


  it 'throws if a string is passed to a number formatter', ->
    throws 'ValueError: unknown format code "c" for String object', ->
      '{:c}'.format('42')

    throws 'ValueError: unknown format code "d" for String object', ->
      '{:d}'.format('42')

    throws 'ValueError: unknown format code "b" for String object', ->
      '{:b}'.format('42')

    throws 'ValueError: unknown format code "o" for String object', ->
      '{:o}'.format('42')

    throws 'ValueError: unknown format code "x" for String object', ->
      '{:x}'.format('42')

    throws 'ValueError: unknown format code "X" for String object', ->
      '{:X}'.format('42')

    throws 'ValueError: unknown format code "f" for String object', ->
      '{:f}'.format('42')

    throws 'ValueError: unknown format code "e" for String object', ->
      '{:e}'.format('42')

    throws 'ValueError: unknown format code "E" for String object', ->
      '{:E}'.format('42')

    throws 'ValueError: unknown format code "g" for String object', ->
      '{:g}'.format('42')

    throws 'ValueError: unknown format code "G" for String object', ->
      '{:G}'.format('42')

    throws 'ValueError: unknown format code "%" for String object', ->
      '{:%}'.format('42')


  it 'provides a format function when "required"', ->
    assert.strictEqual(
      format("The name's {1}. {0} {1}.", 'James', 'Bond')
      "The name's Bond. James Bond.")


  it "passes applicable tests from Python's test suite", ->
    assert.strictEqual ''.format(), ''
    assert.strictEqual 'abc'.format(), 'abc'
    assert.strictEqual '{0}'.format('abc'), 'abc'
    assert.strictEqual 'X{0}'.format('abc'), 'Xabc'
    assert.strictEqual '{0}X'.format('abc'), 'abcX'
    assert.strictEqual 'X{0}Y'.format('abc'), 'XabcY'
    assert.strictEqual '{1}'.format(1, 'abc'), 'abc'
    assert.strictEqual 'X{1}'.format(1, 'abc'), 'Xabc'
    assert.strictEqual '{1}X'.format(1, 'abc'), 'abcX'
    assert.strictEqual 'X{1}Y'.format(1, 'abc'), 'XabcY'
    assert.strictEqual '{0}'.format(-15), '-15'
    assert.strictEqual '{0}{1}'.format(-15, 'abc'), '-15abc'
    assert.strictEqual '{0}X{1}'.format(-15, 'abc'), '-15Xabc'
    assert.strictEqual '{{'.format(), '{'
    assert.strictEqual '}}'.format(), '}'
    assert.strictEqual '{{}}'.format(), '{}'
    assert.strictEqual '{{x}}'.format(), '{x}'
    assert.strictEqual '{{{0}}}'.format(123), '{123}'
    assert.strictEqual '{{{{0}}}}'.format(), '{{0}}'
    assert.strictEqual '}}{{'.format(), '}{'
    assert.strictEqual '}}x{{'.format(), '}x{'

    # computed format specifiers
    assert.strictEqual '{0:.{1}}'.format('hello world', 5), 'hello'
    assert.strictEqual '{0:.{1}s}'.format('hello world', 5), 'hello'
    assert.strictEqual '{1:.{precision}s}'.format({precision: 5}, 'hello world'), 'hello'
    assert.strictEqual '{1:{width}.{precision}s}'.format({width: 10, precision: 5}, 'hello world'), 'hello     '
    assert.strictEqual '{1:{width}.{precision}s}'.format({width: '10', precision: '5'}, 'hello world'), 'hello     '

    # test various errors
    throws 'SyntaxError', -> '{'.format()
    throws 'SyntaxError', -> '}'.format()
    throws 'SyntaxError', -> 'a{'.format()
    throws 'SyntaxError', -> 'a}'.format()
    throws 'SyntaxError', -> '{a'.format()
    throws 'SyntaxError', -> '}a'.format()
    throws 'KeyError', -> '{0}'.format()
    throws 'KeyError', -> '{1}'.format('abc')
    throws 'KeyError', -> '{x}'.format()
    throws 'SyntaxError', -> '}{'.format()
    throws 'SyntaxError', -> 'abc{0:{}'.format()
    throws 'SyntaxError', -> '{0'.format()
    throws 'KeyError', -> '{0.}'.format()
    throws 'KeyError', -> '{0.}'.format(0)
    throws 'KeyError', -> '{0[}'.format()
    throws 'KeyError', -> '{0[}'.format([])
    throws 'KeyError', -> '{0]}'.format()
    throws 'KeyError', -> '{0.[]}'.format(0)
    throws 'KeyError', -> '{0..foo}'.format(0)
    throws 'KeyError', -> '{0[0}'.format(0)
    throws 'KeyError', -> '{0[0:foo}'.format(0)
    throws 'KeyError', -> '{c]}'.format()
    throws 'SyntaxError', -> '{{ {{{0}}'.format(0)
    throws 'SyntaxError', -> '{0}}'.format(0)
    throws 'KeyError', -> '{foo}'.format(bar: 3)
    throws 'ValueError', -> '{0!x}'.format(3)
    throws 'ValueError', -> '{0!}'.format(0)
    throws 'ValueError', -> '{!}'.format()
    throws 'KeyError', -> '{:}'.format()
    throws 'KeyError', -> '{:s}'.format()
    throws 'KeyError', -> '{}'.format()

    # exceed maximum recursion depth
    throws 'ValueError: max string recursion exceeded', ->
      '{0:{1:{2}}}'.format('abc', 's', '')
    throws 'ValueError: max string recursion exceeded', ->
      '{0:{1:{2:{3:{4:{5:{6}}}}}}}'.format(0, 1, 2, 3, 4, 5, 6, 7)

    # string format spec errors
    throws 'ValueError', -> '{0:-s}'.format('')
    throws 'ValueError', -> '{0:=s}'.format('')
