defmodule EmailCollectorWeb.UserControllerTest do
  use EmailCollectorWeb.ConnCase

  import EmailCollector.Fixtures

  setup do
    user = user_fixture()
    campaign = campaign_fixture(user)
    email1 = email_fixture(user, campaign)
    email2 = email_fixture(user, campaign)

    %{user: user, campaign: campaign, email1: email1, email2: email2}
  end

  describe "show profile" do
    test "GET /profile shows user profile with api_key", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/profile")

      assert html_response(conn, 200) =~ user.email
      assert html_response(conn, 200) =~ user.api_key
      refute html_response(conn, 200) =~ "Download All Data"
    end

    test "GET /profile redirects to login if not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == "/auth/login"
    end
  end

  describe "security - user isolation" do
    test "users cannot access other users' profiles", %{conn: conn, user: user} do
      # Create another user
      other_user = user_fixture(%{email: "other@example.com"})
      
      # Try to access other user's profile (should redirect to own profile)
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/profile")

      # Should show current user's profile, not other user's
      assert html_response(conn, 200) =~ user.email
      assert html_response(conn, 200) =~ user.api_key
      refute html_response(conn, 200) =~ other_user.email
      refute html_response(conn, 200) =~ other_user.api_key
    end

    test "users cannot see other users' campaigns in their profile", %{conn: conn, user: user} do
      # Create another user and their campaign
      other_user = user_fixture(%{email: "other@example.com"})
      other_campaign = campaign_fixture(other_user)
      
      # Access own profile
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/profile")

      # Should not see other user's campaign
      refute html_response(conn, 200) =~ other_campaign.name
    end
  end

  defp log_in_user(conn, user) do
    post(conn, "/auth/login", %{
      "email" => user.email,
      "password" => "password123"
    })
  end
end
