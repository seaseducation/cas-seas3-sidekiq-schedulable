require 'spec_helper'

describe Sidekiq::Schedulable do
  it 'has a version number' do
    expect(Sidekiq::Schedulable::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
