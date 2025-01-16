# frozen_string_literal: true

RSpec.shared_examples 'render_and_assert' do
  let(:templates) { {} }
  let(:extensions) { [] }
  let(:call_context) { nil }

  it 'matches the output' do
    results = outputs.strip.split("\n")
    inputs.strip.split("\n").each_with_index do |line, index|
      expect(render(line, locals)).to eq(results[index])
    end
  end

  def render(source, context)
    loader = Twig::Loader::Array.new({
      template: source,
      **templates,
    })

    environment = Twig::Environment.new(loader)

    extensions.each do |extension|
      environment.add_extension(extension)
    end

    environment.
      load_template('template', call_context:).
      render(context).
      to_s
  end
end
