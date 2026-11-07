# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext/class/attribute'
require 'active_support/environment_inquirer'
require 'active_support/ordered_options'
require 'pathname'
require_relative '../../../../lib/twig/rails/config'
require_relative '../../../../lib/twig/rails/escaping_strategy'

# Rails isn't a dependency of this suite, so these stand in for the two things
# Config reads from it: Rails.env and Rails.root.
describe Twig::Rails::Config do
  def defaults_in(env)
    stub_const('Rails', Module.new)
    allow(Rails).to receive_messages(
      env: ActiveSupport::EnvironmentInquirer.new(env),
      root: Pathname.new('/app')
    )

    described_class.defaults
  end

  describe 'auto_reload' do
    it 'checks templates against the cache in development' do
      expect(defaults_in('development').auto_reload).to be(true)
    end

    # The cache in tmp/cache/twig outlives the test process, so without a
    # freshness check a test run would keep rendering templates compiled
    # before an edit.
    it 'checks templates against the cache in test' do
      expect(defaults_in('test').auto_reload).to be(true)
    end

    it 'trusts the cache in production' do
      expect(defaults_in('production').auto_reload).to be(false)
    end
  end

  it 'only turns on debug in development' do
    expect(defaults_in('development').debug).to be(true)
    expect(defaults_in('test').debug).to be(false)
  end

  it 'leaves the Rails text format unescaped and escapes html' do
    autoescape = defaults_in('test').autoescape

    expect(autoescape.call('app/views/mailer/welcome.text.twig')).to be(false)
    expect(autoescape.call('app/views/mailer/welcome.html.twig')).to eq(:html)
  end

  it 'gives each environment its own cache under tmp/cache/twig' do
    expect(defaults_in('development').cache).to eq('/app/tmp/cache/twig/development')
    expect(defaults_in('test').cache).to eq('/app/tmp/cache/twig/test')
  end
end
