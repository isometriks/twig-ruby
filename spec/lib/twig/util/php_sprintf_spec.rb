# frozen_string_literal: true

require 'spec_helper'

# The expected values are what PHP's sprintf gives
RSpec.describe Twig::Util::PhpSprintf do
  def php_sprintf(format, *)
    described_class.call(format, *)
  end

  it 'writes an exponent without leading zeros' do
    expect(php_sprintf('%e|%5.1e|%E', 12_345.678, 0.000123, 0.0)).to eq('1.234568e+4|1.2e-4|0.000000E+0')
  end

  it 'pads with the character after a quote' do
    expect(php_sprintf("%'*10s|%'x-5d", 'hi', 3)).to eq('********hi|3xxxx')
  end

  it 'pads a string on the right with 0, but never an integer' do
    expect(php_sprintf('%-05d|%-05s|%+05d|%05.1f', -3, 'ab', 3, -2.25)).to eq('-3   |ab000|+0003|-02.2')
  end

  it 'reads numbers the way PHP converts them' do
    expect(php_sprintf('%d|%d|%d|%d|%d|%d', '12abc', nil, true, '1e3', ' 42', '1.9')).to eq('12|0|1|1000|42|1')
    expect(php_sprintf('%f|%.1f', '1.5x', 'abc')).to eq('1.500000|0.0')
  end

  it 'prints a negative number as unsigned for %u, %x, %o and %b' do
    expect(php_sprintf('%u|%x|%X|%o|%b', -3, -1, 255, 8, 5)).to eq('18446744073709551613|ffffffffffffffff|FF|10|101')
  end

  it 'converts floats to strings like PHP' do
    expect(php_sprintf('%s|%s|%s|%s|%s|%s', 1.0e15, 0.1 + 0.2, -0.0, 1.0e-5, 100.0, 1.0)).
      to eq('1.0E+15|0.3|-0|1.0E-5|100|1')
    expect(php_sprintf('%s|%s|%s', true, false, nil)).to eq('1||')
  end

  it 'formats %g like PHP' do
    expect(php_sprintf('%g|%G|%g|%g', 0.00001234, 1.0e20, 100_000.0, 1_234_567.0)).
      to eq('1.234e-5|1.0E+20|100000|1.23457e+6')
  end

  it 'rounds the exact binary value, with a tie going to the even digit' do
    expect(php_sprintf('%.2f|%.1f|%.2f|%.2f|%.0f|%.0f', 2.675, 0.35, 9.995, 0.125, 2.5, 0.5)).
      to eq('2.67|0.3|9.99|0.12|2|0')
    expect(php_sprintf('%.2e|%.13e|%.0e|%.3g|%.20f', 2.675, 7.05017039081155, 0.015, 2.675, 0.1)).
      to eq('2.67e+0|7.0501703908115e+0|1e-2|2.67|0.10000000000000000555')
    expect(php_sprintf('%s|%s|%.2f', 7.05017039081155, 5.0e-324, 99.995)).
      to eq('7.0501703908115|4.9406564584125E-324|100.00')
  end

  it 'takes arguments by position' do
    expect(php_sprintf('%2$s %1$s %2$s', 'a', 'b')).to eq('b a b')
  end

  it 'takes a width and a precision from the arguments' do
    expect(php_sprintf('%*d|%.*f|%-*s|', 5, 42, 2, 3.14159, 3, 'x')).to eq('   42|3.14|x  |')
  end

  it 'counts and cuts bytes' do
    expect(php_sprintf('%.3s|%5s', 'abcdef', 'é')).to eq('abc|   é')
  end

  it 'raises like PHP' do
    expect { php_sprintf('%s %s', 'a') }.to raise_error(ArgumentError, '3 arguments are required, 2 given')
    expect { php_sprintf('%y', 'a') }.to raise_error(ArgumentError, 'Unknown format specifier "y"')
    expect { php_sprintf('a%', 'a') }.to raise_error(ArgumentError, 'Missing format specifier at end of string')
    expect { php_sprintf('%0$s', 'a') }.to raise_error(
      ArgumentError, 'Argument number specifier must be greater than zero and less than 2147483647'
    )
  end
end
