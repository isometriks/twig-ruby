# frozen_string_literal: true

RSpec.shared_examples 'render_and_assert' do
  let(:options) { {} }
  let(:input) { raise NotImplementedError }
  let(:inputs) { [input] }
  let(:output) { raise NotImplementedError }
  let(:outputs) { [output] }
  let(:locals) { {} }
  let(:templates) { {} }
  let(:extensions) { [] }
  let(:call_context) { nil }

  it 'matches the output' do
    results = outputs.is_a?(Array) ? outputs : outputs.strip.split("\n")
    templates = inputs.is_a?(Array) ? inputs : inputs.strip.split("\n")
    templates.each_with_index do |line, index|
      expect(render(line, locals)).to eq(results[index])
    end
  end

  def render(source, context)
    loader = Twig::Loader::Array.new({
      template: source,
      **templates,
    })

    environment = Twig::Environment.new(loader, { debug: true }.merge(options))

    extensions.each do |extension|
      environment.add_extension(extension)
    end

    environment.
      load('template').
      render(context, call_context:).
      to_s
  end
end

RSpec.shared_examples 'render_and_raise' do
  let(:template) { raise NotImplementedError, 'Set template to render' }
  let(:loader) { Twig::Loader::Array.new({ 'template.twig' => template }) }
  let(:environment) { Twig::Environment.new(loader) }
  let(:error) { NotImplementedError }
  let(:message) { raise NotImplementedError, 'Add regex error message to match' }

  it 'raises expected error' do
    expect do
      environment.load('template.twig').render
    end.to raise_error(error, message)
  end
end
