defmodule EmailCollectorWeb.AuthControllerTest do
  use EmailCollectorWeb.ConnCase

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
      assert html_response(conn, 200) =~ "invalid"
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
end
