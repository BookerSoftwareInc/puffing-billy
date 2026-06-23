# frozen_string_literal: true

require 'spec_helper'

describe 'Watir-specific tests', :js, type: :feature do
  before do
    proxy.stub('http://www.example.com/get').and_return(
      text: 'Success!'
    )
  end

  it 'raises a NameError if an invalid browser driver is specified' do
    expect { Billy::Browsers::Watir.new :invalid }.to raise_error(NameError)
  end

  it 'responds to a stubbed GET request' do
    @browser.goto 'http://www.example.com/get'
    expect(@browser.text).to eq 'Success!'
  end
end
