require "rails_helper"
require "shared_examples"
require "jwt"
require "test_prof/recipes/rspec/let_it_be"

RSpec.describe API::V1::Users, type: :request do
  describe "PATCH /api/v1/users" do
    let(:user) {create(:user)}
    let(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let(:full_update_params) {{name: "tester", email: "tester@gmail.com",
                               password: 123456, password_confirmation: 123456}}

    context "edit success" do
      before do
        patch "/api/v1/users", params: full_update_params,
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "should inform edit success" do
        expect(JSON.parse(response.body)["data"]["message"]).to eq("update success")
      end

      it "should return user with new info edit" do
        user.reload
        expect(JSON.parse(response.body)["data"]["user"]).to include("email" => user.email, "name" => user.name,
                                                                              "password_digest" => user.password_digest)
      end
    end

    context "edit failed with not login" do
      before do
        patch "/api/v1/users", params: full_update_params
      end

      include_examples "status error"

      include_examples "api error not login"
    end

    context "update failed with unconfirmed password" do
      before do
        patch "/api/v1/users", params: {password: 123456},
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      it "inform password must be confirmed" do
        expect(JSON.parse(response.body)["message"]).to eq("Must confirm your password")
      end
    end

    context "update failed with invalid params" do
      before do
        patch "/api/v1/users", params: {email: "tester", password: 123456, password_confirmation: 123456},
                               headers: {Authorization: "Bearer #{user_token}"}
      end

      it "inform an array of errors" do
        expect(JSON.parse(response.body)["message"]).to be_an_instance_of(Array)
      end
    end
  end

  describe "GET /api/v1/users/:id/tests" do
    let_it_be(:user) {create(:user)}
    let_it_be(:user_token) {JWT.encode({id: user.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:supervisor) {create(:supervisor)}
    let_it_be(:supervisor_token) {JWT.encode({id: supervisor.id}, ENV["hmac_secret"], "HS256")}
    let_it_be(:user_tests) {
      list = create_list(:test, 5, user: user) << create_list(:finished_test, 5, user: user)
      list.flatten
    }

    context "show success" do
      before do
        get "/api/v1/users/#{user.id}/tests", headers: {Authorization: "Bearer #{supervisor_token}"}
      end

      include_examples "status success"
      include_examples "status code 200"

      it "show user's history" do
        expect(JSON.parse(response.body)["data"].size).to eq(10)
      end

      it "order desc created_at" do
        expect(JSON.parse(response.body)["data"].pluck(:id).sort {|a, b| b <=> a}).to eq(JSON.parse(response.body)["data"].pluck(:id))
      end
    end

    context "failed with unauthorized" do
      before do
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/tests", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"

      it "inform access denied" do
        expect(JSON.parse(response.body)["message"]).to eq("You can not access history")
      end
    end

    context "failed with not login" do
      before do
        get "/api/v1/users/#{user.id}/tests"
      end

      include_examples "status error"
      include_examples "api error not login"
    end

    context "failed with user not_found" do
      before do
        get "/api/v1/users/#{-1}/tests", headers: {Authorization: "Bearer #{user_token}"}
      end

      include_examples "status error"

      it "inform user not found" do
        expect(JSON.parse(response.body)["message"]).to eq("User not found")
      end
    end

    context "failed with invalid params" do
      context "negative page or per_page" do
        before do
          get "/api/v1/users/#{user.id}/tests", params: {page: 1, per_page: -1}, headers: {Authorization: "Bearer #{user_token}"}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
        end
      end

      context "page or per_page is not a number" do
        before do
          get "/api/v1/users/#{user.id}/tests", params: {page: "a", per_page: 10}, headers: {Authorization: "Bearer #{user_token}"}
        end

        it "returns status 400" do
          expect(response).to have_http_status(400)
        end

        it "returns error message" do
          expect(JSON.parse(response.body)["message"]).to eq("One or more parameters are invalid")
        end
      end
    end
  end
end
