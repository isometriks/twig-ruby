RSpec.shared_examples 'render_and_assert' do
  it 'matches the output' do
    results = outputs.strip.split(/\n/)
    inputs.strip.split(/\n/).each_with_index do |line, index|
      expect(render(line, locals)).to eq(results[index])
    end
  end

  def render(source, context)
    loader = Twig::Loader::Array.new({ template: source })
    environment = Twig::Environment.new(loader)

    environment.
      load_template('template').
      new(environment).
      render(context).
      to_s
  end
end
