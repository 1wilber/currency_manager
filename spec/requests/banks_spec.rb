require 'rails_helper'

RSpec.describe "Banks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/banks/index"
      expect(response).to have_http_status(:success)
    end
  end

end
