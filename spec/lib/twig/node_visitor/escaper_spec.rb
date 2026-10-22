# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::NodeVisitor::Escaper do
  context 'when a compilation error happens inside an autoescape tag' do
    let(:loader) do
      Twig::Loader::Hash.new({
        'escaper_reset/broken.html' => '{% autoescape false %}{{ foo|failing|nl2br }}{% endautoescape %}',
        'escaper_reset/index.html' => '{{ foo }}',
        'escaper_reset/index.txt' => '{{ foo }}',
      })
    end

    let(:environment) do
      Twig::Environment.new(loader, autoescape: :name).tap do |env|
        env.add_extension(Class.new(Twig::Extension::Base) do
          def filters
            [
              Twig::TwigFilter.new('failing', ->(value) { value }, {
                is_safe_callback: ->(_args) { raise 'Unable to compute the safety of the filter.' },
              }),
            ]
          end
        end.new)
      end
    end

    it 'does not affect the escaping of the next template' do
      expect { environment.load('escaper_reset/broken.html') }.to raise_error(/Unable to compute the safety/)

      expect(environment.load('escaper_reset/index.txt').render({ foo: '<br>' })).to eq('<br>')
      expect(environment.load('escaper_reset/index.html').render({ foo: '<br>' })).to eq('&lt;br&gt;')
    end
  end
end
