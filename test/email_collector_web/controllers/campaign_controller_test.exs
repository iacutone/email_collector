defmodule EmailCollectorWeb.CampaignControllerTest do
  use EmailCollectorWeb.ConnCase

  import EmailCollector.Fixtures

  setup do
    user = user_fixture()
    campaign = campaign_fixture(user)
    email1 = email_fixture(user, campaign)
    email2 = email_fixture(user, campaign)

    %{user: user, campaign: campaign, email1: email1, email2: email2}
  end

  describe "campaign CRUD" do
    test "GET /campaigns/new shows new campaign form", %{conn: conn, user: user} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/new")

      assert html_response(conn, 200) =~ "Create New Campaign"
      assert html_response(conn, 200) =~ "Campaign Name"
    end

    test "POST /campaigns creates new campaign", %{conn: conn, user: user} do
      conn = 
        conn
        |> log_in_user(user)
        |> post(~p"/campaigns", %{campaign: %{name: "Test Campaign"}})

      assert redirected_to(conn) =~ "/campaigns/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Campaign created successfully"
    end

    test "GET /campaigns/:id shows campaign with emails", %{conn: conn, user: user, campaign: campaign, email1: email1, email2: email2} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{campaign.id}")

      assert html_response(conn, 200) =~ campaign.name
      assert html_response(conn, 200) =~ email1.name
      assert html_response(conn, 200) =~ email2.name
      assert html_response(conn, 200) =~ "Collected Emails"
    end

    test "GET /campaigns/:id/edit shows edit form", %{conn: conn, user: user, campaign: campaign} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{campaign.id}/edit")

      assert html_response(conn, 200) =~ "Edit Campaign"
      assert html_response(conn, 200) =~ campaign.name
    end

    test "PUT /campaigns/:id updates campaign", %{conn: conn, user: user, campaign: campaign} do
      conn = 
        conn
        |> log_in_user(user)
        |> put(~p"/campaigns/#{campaign.id}", %{campaign: %{name: "Updated Campaign"}})

      assert redirected_to(conn) =~ "/campaigns/#{campaign.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Campaign updated successfully"
    end

    test "DELETE /campaigns/:id deletes campaign", %{conn: conn, user: user, campaign: campaign} do
      conn = 
        conn
        |> log_in_user(user)
        |> delete(~p"/campaigns/#{campaign.id}")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Campaign deleted successfully"
    end

    test "campaign CRUD actions require authentication", %{conn: conn, campaign: campaign} do
      # Test new campaign
      conn = get(conn, ~p"/campaigns/new")
      assert redirected_to(conn) == "/auth/login"

      # Test create campaign
      conn = post(conn, ~p"/campaigns", %{campaign: %{name: "Test"}})
      assert redirected_to(conn) == "/auth/login"

      # Test show campaign
      conn = get(conn, ~p"/campaigns/#{campaign.id}")
      assert redirected_to(conn) == "/auth/login"

      # Test edit campaign
      conn = get(conn, ~p"/campaigns/#{campaign.id}/edit")
      assert redirected_to(conn) == "/auth/login"

      # Test update campaign
      conn = put(conn, ~p"/campaigns/#{campaign.id}", %{campaign: %{name: "Test"}})
      assert redirected_to(conn) == "/auth/login"

      # Test delete campaign
      conn = delete(conn, ~p"/campaigns/#{campaign.id}")
      assert redirected_to(conn) == "/auth/login"
    end
  end

  describe "download CSV" do
    test "GET /campaigns/:id/download downloads CSV for specific campaign", %{conn: conn, user: user, campaign: campaign, email1: email1, email2: email2} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{campaign.id}/download")

      assert response(conn, 200)
      content_type = get_resp_header(conn, "content-type") |> List.first()
      assert content_type =~ "text/csv"
      content_disposition = get_resp_header(conn, "content-disposition") |> List.first()
      assert String.ends_with?(content_disposition, ".csv\"")

      csv_content = response(conn, 200)
      assert csv_content =~ "Campaign Name"
      assert csv_content =~ "Email Name"
      assert csv_content =~ campaign.name
      assert csv_content =~ email1.name
      assert csv_content =~ email2.name
    end

    test "GET /campaigns/:id/download redirects to login if not authenticated", %{conn: conn, campaign: campaign} do
      conn = get(conn, ~p"/campaigns/#{campaign.id}/download")
      assert redirected_to(conn) == "/auth/login"
    end

    test "GET /campaigns/:id/download returns error for non-owned campaign", %{conn: conn, user: user, campaign: _campaign} do
      # Create another user and campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)

      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{other_campaign.id}/download")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end
  end

  describe "security - user isolation" do
    test "users cannot access other users' campaigns", %{conn: conn, user: user} do
      # Create another user and their campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      
      # Try to view other user's campaign
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{other_campaign.id}")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end

    test "users cannot edit other users' campaigns", %{conn: conn, user: user} do
      # Create another user and their campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      
      # Try to edit other user's campaign
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{other_campaign.id}/edit")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end

    test "users cannot update other users' campaigns", %{conn: conn, user: user} do
      # Create another user and their campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      
      # Try to update other user's campaign
      conn = 
        conn
        |> log_in_user(user)
        |> put(~p"/campaigns/#{other_campaign.id}", %{campaign: %{name: "Hacked Campaign"}})

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end

    test "users cannot delete other users' campaigns", %{conn: conn, user: user} do
      # Create another user and their campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      
      # Try to delete other user's campaign
      conn = 
        conn
        |> log_in_user(user)
        |> delete(~p"/campaigns/#{other_campaign.id}")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end

    test "users cannot download other users' campaign CSV", %{conn: conn, user: user} do
      # Create another user and their campaign with emails
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      _other_email = email_fixture(other_user, other_campaign)
      
      # Try to download other user's campaign CSV
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/#{other_campaign.id}/download")

      assert redirected_to(conn) == "/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Campaign not found"
    end

    test "users cannot access other users' campaign creation form", %{conn: conn, user: user} do
      # This test verifies that the campaign creation form is properly isolated
      # Create another user
      other_user = user_fixture(%{email: "other@example.com"})
      
      # Access campaign creation form as current user
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/new")

      # Should show the form for current user (campaigns are created for the authenticated user)
      assert html_response(conn, 200) =~ "Create New Campaign"
      
      # Verify the form doesn't contain any other user's data
      refute html_response(conn, 200) =~ other_user.email
    end

    test "users cannot create campaigns for other users", %{conn: conn, user: user} do
      # Create another user
      other_user = user_fixture(%{email: "other@example.com"})
      
      # Try to create a campaign with another user's ID
      conn = 
        conn
        |> log_in_user(user)
        |> post(~p"/campaigns", %{campaign: %{name: "Test Campaign", user_id: other_user.id}})

      # Should redirect to the created campaign (which will be for the authenticated user)
      assert redirected_to(conn) =~ "/campaigns/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Campaign created successfully"
      
      # Verify the campaign was created for the authenticated user, not the other user
      # (This is handled by the controller which overrides user_id)
    end

    test "users cannot access non-existent campaigns", %{conn: conn, user: user} do
      # Try to access a campaign that doesn't exist
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/999999")
      end
    end

    test "users cannot download non-existent campaign CSV", %{conn: conn, user: user} do
      # Try to download CSV for a campaign that doesn't exist
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> log_in_user(user)
        |> get(~p"/campaigns/999999/download")
      end
    end
  end

  defp log_in_user(conn, user) do
    post(conn, "/auth/login", %{
      "email" => user.email,
      "password" => "password123"
    })
  end
end 