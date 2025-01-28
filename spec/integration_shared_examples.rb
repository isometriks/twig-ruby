# frozen_string_literal: true

RSpec.shared_examples 'render_and_assert' do
  let(:options) { {} }
  let(:inputs) { raise NotImplementedError }
  let(:outputs) { raise NotImplementedError }
  let(:locals) { {} }
  let(:templates) { {} }
  let(:extensions) { [] }
  let(:call_context) { nil }

  it 'matches the output' do
    results = outputs.is_a?(Array) ? outputs : outputs.strip.split("\n")
    inputs.strip.split("\n").each_with_index do |line, index|
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
      load_template('template', call_context:).
      render(context).
      to_s
  end
end
