defmodule EmailCollectorWeb.Api.EmailControllerTest do
  use EmailCollectorWeb.ConnCase

  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  @valid_email_params %{name: "Recipient"}

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
    test "creates email with valid api_key and campaign", %{
      conn: conn,
      user: user,
      campaign: campaign
    } do
      conn = conn |> auth_conn(user.api_key)
      resp = post(conn, "/api/v1/emails/#{campaign.id}", %{email: @valid_email_params})
      assert resp.status == 201
      resp_body = json_response(resp, 201)
      assert resp_body["id"]
      assert resp_body["name"] == "Recipient"
      assert resp_body["campaign_id"] == campaign.id
    end

    test "returns 401 for invalid api_key", %{conn: conn, campaign: campaign} do
      conn = conn |> auth_conn("badkey")
      resp = post(conn, "/api/v1/emails/#{campaign.id}", %{email: @valid_email_params})
      assert resp.status == 401
    end

    test "returns 403 for campaign not owned by user", %{conn: conn, user: user} do
      {:ok, other_user} =
        Accounts.create_user(%{
          email: "other@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, other_campaign} = Campaigns.create_campaign(%{name: "Other", user_id: other_user.id})
      conn = conn |> auth_conn(user.api_key)
      resp = post(conn, "/api/v1/emails/#{other_campaign.id}", %{email: @valid_email_params})
      assert resp.status == 403
    end

    test "returns 404 for non-existent campaign", %{conn: conn, user: user} do
      conn = conn |> auth_conn(user.api_key)
      resp = post(conn, "/api/v1/emails/999999", %{email: @valid_email_params})
      assert resp.status == 404
    end
  end

  describe "GET /api/v1/emails/:campaign_id" do
    test "lists emails for campaign", %{conn: conn, user: user, campaign: campaign} do
      {:ok, email1} =
        Emails.create_email(%{name: "A", user_id: user.id, campaign_id: campaign.id})

      {:ok, email2} =
        Emails.create_email(%{name: "B", user_id: user.id, campaign_id: campaign.id})

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
end
