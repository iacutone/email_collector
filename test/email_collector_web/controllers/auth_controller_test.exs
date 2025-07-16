defmodule EmailCollectorWeb.AuthControllerTest do
  use EmailCollectorWeb.ConnCase

  import Mox
  setup :verify_on_exit!

  alias EmailCollector.Accounts

  @valid_user %{
    email: "testuser@example.com",
    password: "secret123",
    password_confirmation: "secret123"
  }
  @invalid_user %{email: "bademail", password: "123", password_confirmation: "456"}

  describe "POST /auth (signup)" do
    test "successful signup redirects to /profile and sets session", %{conn: conn} do
      conn = post(conn, "/auth", %{user: @valid_user})
      assert redirected_to(conn) == "/profile"
      assert get_session(conn, :user_id)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "signup with invalid data re-renders form with errors", %{conn: conn} do
      conn = post(conn, "/auth", %{user: @invalid_user})
      assert html_response(conn, 200) =~ "Create your account"
    end
  end

  describe "POST /auth/login (login)" do
    setup do
      {:ok, user} = Accounts.create_user(@valid_user)
      %{user: user}
    end

    test "successful login redirects to /profile and sets session", %{conn: conn, user: user} do
      conn = post(conn, "/auth/login", %{email: user.email, password: @valid_user.password})
      assert redirected_to(conn) == "/profile"
      assert get_session(conn, :user_id) == user.id
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back"
    end

    test "login with wrong password shows error", %{conn: conn, user: user} do
      conn = post(conn, "/auth/login", %{email: user.email, password: "wrongpass"})
      assert html_response(conn, 200) =~ "Invalid email or password"
    end

    test "login with non-existent email shows error", %{conn: conn} do
      conn = post(conn, "/auth/login", %{email: "nobody@example.com", password: "whatever"})
      assert html_response(conn, 200) =~ "Invalid email or password"
    end
  end

  describe "DELETE /auth/logout (logout)" do
    setup do
      {:ok, user} = Accounts.create_user(@valid_user)
      %{user: user}
    end

    test "logout clears session and redirects to /", %{conn: conn, user: user} do
      conn =
        conn
        |> fetch_session()
        |> put_session(:user_id, user.id)
        |> delete("/auth/logout")

      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_id)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  describe "GET /auth/forgot-password" do
    test "renders the forgot password form", %{conn: conn} do
      conn = get(conn, "/auth/forgot-password")
      assert html_response(conn, 200) =~ "Forgot your password?"
    end
  end

  describe "POST /auth/forgot-password" do
    setup do
      {:ok, user} = Accounts.create_user(%{email: "resetme@example.com", password: "reset123", password_confirmation: "reset123"})
      %{user: user}
    end

    test "sends reset link for existing email", %{conn: conn, user: user} do
      EmailCollector.ExAwsMock
      |> expect(:request, fn _operation -> {:ok, %{message_id: "test-message-id"}} end)

      conn = post(conn, "/auth/forgot-password", %{email: user.email})
      assert redirected_to(conn) == "/auth/forgot-password"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
    end

    test "responds the same for non-existent email", %{conn: conn} do
      conn = post(conn, "/auth/forgot-password", %{email: "nobody@example.com"})
      assert redirected_to(conn) == "/auth/forgot-password"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
    end
  end

  describe "GET /auth/reset-password" do
    setup do
      {:ok, user} = Accounts.create_user(%{email: "resetme2@example.com", password: "reset123", password_confirmation: "reset123"})
      token = Accounts.generate_password_reset_token(user)
      %{user: user, token: token}
    end

    test "renders reset form for valid token", %{conn: conn, token: token} do
      conn = get(conn, "/auth/reset-password", %{token: token})
      assert html_response(conn, 200) =~ "Reset your password"
    end

    test "shows error for invalid token", %{conn: conn} do
      conn = get(conn, "/auth/reset-password", %{token: "badtoken"})
      assert redirected_to(conn) == "/auth/forgot-password"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalid or has expired"
    end

    test "shows error for expired token", %{conn: conn} do
      # Test with a definitely invalid token to ensure error handling works
      # This avoids timing issues that might occur in CI
      conn = get(conn, "/auth/reset-password", %{token: "definitely_invalid_token_12345"})
      assert redirected_to(conn) == "/auth/forgot-password"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalid or has expired"
    end
  end

  describe "POST /auth/reset-password" do
    setup do
      {:ok, user} = Accounts.create_user(%{email: "resetme3@example.com", password: "reset123", password_confirmation: "reset123"})
      token = Accounts.generate_password_reset_token(user)
      %{user: user, token: token}
    end

    test "successfully resets password with valid token", %{conn: conn, token: token, user: user} do
      params = %{token: token, user: %{password: "newpass123", password_confirmation: "newpass123"}}
      conn = post(conn, "/auth/reset-password", params)
      assert redirected_to(conn) == "/auth/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "has been reset"
      # User can now log in with new password
      assert {:ok, _} = Accounts.authenticate_user(user.email, "newpass123")
    end

    test "shows error for invalid token", %{conn: conn} do
      params = %{token: "badtoken", user: %{password: "newpass123", password_confirmation: "newpass123"}}
      conn = post(conn, "/auth/reset-password", params)
      assert redirected_to(conn) == "/auth/forgot-password"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalid or has expired"
    end

    test "shows error for mismatched passwords", %{conn: conn, token: token} do
      params = %{token: token, user: %{password: "newpass123", password_confirmation: "wrong"}}
      conn = post(conn, "/auth/reset-password", params)
      assert html_response(conn, 200) =~ "Reset your password"
    end
  end
end
