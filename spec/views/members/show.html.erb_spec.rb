# frozen_string_literal: true

require "rails_helper"
require Rails.root.join('spec', 'support', 'shared_examples.rb')

# rubocop: disable RSpec/DescribeClass
RSpec.describe "members/show" do
  it_behaves_like "a view without missing translations" do
    before {
      assign(:member, build_stubbed(:member))
      allow(view).to receive(:current_member) { build_stubbed :member }
    }
  end
end

RSpec.describe "member/show.html.erb", type: :view do
	context 'it display the end_subscription' do
		it "displays end_subscription" do
			assign(:member, build(:member, end_subscription: DateTime.new(2020, 10, 10) ))
			render
			expect(rendered).to match DateTime.new(2020, 10, 10)
		end
	end
end
# rubocop: enable RSpec/DescribeClass
