require 'rails_helper'

RSpec.describe Bank, type: :model do
  context "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:currency) }
  end

  context "associations" do
  end
end
