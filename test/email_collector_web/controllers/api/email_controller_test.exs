defmodule EmailCollectorWeb.Api.EmailControllerTest do
  use EmailCollectorWeb.ConnCase

  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  @valid_email_params %{name: "test@example.com"}

  setup do
    {:ok, user} =
      Accounts.create_user(%{
        email: "api@example.com",
        password: "pw1234",
        password_confirmation: "pw1234"
      })

    {:ok, campaign} = Campaigns.create_campaign(%{name: "API Test", user_id: user.id})
    %{user: user, campaign: campaign}
  end

  def auth_conn(conn, api_key), do: put_req_header(conn, "authorization", "Bearer #{api_key}")

  describe "POST /api/v1/emails/:campaign_id" do
    test "creates email without authentication", %{
      conn: conn,
      campaign: campaign
    } do
      resp = post(conn, "/api/v1/emails/#{campaign.id}", %{email: @valid_email_params})
      assert resp.status == 201
      resp_body = json_response(resp, 201)
      assert resp_body["id"]
      assert resp_body["name"] == "test@example.com"
      assert resp_body["campaign_id"] == campaign.id
    end

    test "creates email for any campaign (no ownership check)", %{conn: conn} do
      {:ok, other_user} =
        Accounts.create_user(%{
          email: "other@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, other_campaign} = Campaigns.create_campaign(%{name: "Other", user_id: other_user.id})
      resp = post(conn, "/api/v1/emails/#{other_campaign.id}", %{email: @valid_email_params})
      assert resp.status == 201
      resp_body = json_response(resp, 201)
      assert resp_body["id"]
      assert resp_body["name"] == "test@example.com"
      assert resp_body["campaign_id"] == other_campaign.id
    end

    test "returns 404 for non-existent campaign", %{conn: conn} do
      resp = post(conn, "/api/v1/emails/999999", %{email: @valid_email_params})
      assert resp.status == 404
    end

    test "rejects invalid email addresses", %{conn: conn, campaign: campaign} do
      resp = post(conn, "/api/v1/emails/#{campaign.id}", %{email: %{name: "invalid-email"}})
      assert resp.status == 422
      resp_body = json_response(resp, 422)
      assert resp_body["error"] == "Invalid email data"
      assert resp_body["details"]["name"] == ["must be a valid email address"]
    end
  end

  describe "GET /api/v1/emails/:campaign_id" do
    test "lists emails for campaign", %{conn: conn, user: user, campaign: campaign} do
      {:ok, email1} =
        Emails.create_email(%{
          name: "user1@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      {:ok, email2} =
        Emails.create_email(%{
          name: "user2@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      conn = conn |> auth_conn(user.api_key)
      resp = get(conn, "/api/v1/emails/#{campaign.id}")
      assert resp.status == 200
      emails = json_response(resp, 200)
      assert Enum.any?(emails, &(&1["id"] == email1.id))
      assert Enum.any?(emails, &(&1["id"] == email2.id))
    end

    test "returns 401 for invalid api_key", %{conn: conn, campaign: campaign} do
      conn = conn |> auth_conn("badkey")
      resp = get(conn, "/api/v1/emails/#{campaign.id}")
      assert resp.status == 401
    end

    test "returns 403 for campaign not owned by user", %{conn: conn, user: user} do
      {:ok, other_user} =
        Accounts.create_user(%{
          email: "other2@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, other_campaign} = Campaigns.create_campaign(%{name: "Other2", user_id: other_user.id})
      conn = conn |> auth_conn(user.api_key)
      resp = get(conn, "/api/v1/emails/#{other_campaign.id}")
      assert resp.status == 403
    end

    test "returns 404 for non-existent campaign", %{conn: conn, user: user} do
      conn = conn |> auth_conn(user.api_key)
      resp = get(conn, "/api/v1/emails/999999")
      assert resp.status == 404
    end
  end

  describe "POST /api/v1/emails/:campaign_id/unsubscribe" do
    test "unsubscribes an email without authentication", %{
      conn: conn,
      user: user,
      campaign: campaign
    } do
      {:ok, email} =
        Emails.create_email(%{
          name: "subscriber@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      assert email.subscribed == true

      resp =
        post(conn, "/api/v1/emails/#{campaign.id}/unsubscribe", %{
          email: "subscriber@example.com"
        })

      assert resp.status == 200
      resp_body = json_response(resp, 200)
      assert resp_body["message"] == "Successfully unsubscribed"
      assert resp_body["email"] == "subscriber@example.com"
      assert resp_body["subscribed"] == false

      # Verify the email was actually updated in the database
      updated_email = Emails.get_email!(email.id)
      assert updated_email.subscribed == false
    end

    test "returns 404 for non-existent campaign", %{conn: conn} do
      resp =
        post(conn, "/api/v1/emails/999999/unsubscribe", %{email: "test@example.com"})

      assert resp.status == 404
      resp_body = json_response(resp, 404)
      assert resp_body["error"] == "Campaign not found"
    end

    test "returns 404 for email not in campaign", %{conn: conn, campaign: campaign} do
      resp =
        post(conn, "/api/v1/emails/#{campaign.id}/unsubscribe", %{
          email: "nonexistent@example.com"
        })

      assert resp.status == 404
      resp_body = json_response(resp, 404)
      assert resp_body["error"] == "Email not found in this campaign"
    end

    test "unsubscribing already unsubscribed email is idempotent", %{
      conn: conn,
      user: user,
      campaign: campaign
    } do
      {:ok, email} =
        Emails.create_email(%{
          name: "already_unsubscribed@example.com",
          user_id: user.id,
          campaign_id: campaign.id
        })

      # Unsubscribe once
      {:ok, _} = Emails.unsubscribe_email(email)

      # Unsubscribe again
      resp =
        post(conn, "/api/v1/emails/#{campaign.id}/unsubscribe", %{
          email: "already_unsubscribed@example.com"
        })

      assert resp.status == 200
      resp_body = json_response(resp, 200)
      assert resp_body["subscribed"] == false
    end

    test "unsubscribe works for any campaign (no ownership check)", %{conn: conn} do
      {:ok, other_user} =
        Accounts.create_user(%{
          email: "other3@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, other_campaign} =
        Campaigns.create_campaign(%{name: "Other3", user_id: other_user.id})

      {:ok, email} =
        Emails.create_email(%{
          name: "unsubscribe_other@example.com",
          user_id: other_user.id,
          campaign_id: other_campaign.id
        })

      resp =
        post(conn, "/api/v1/emails/#{other_campaign.id}/unsubscribe", %{
          email: "unsubscribe_other@example.com"
        })

      assert resp.status == 200
      updated_email = Emails.get_email!(email.id)
      assert updated_email.subscribed == false
    end
  end
end
