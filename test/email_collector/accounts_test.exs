defmodule EmailCollector.AccountsTest do
  use EmailCollector.DataCase

  alias EmailCollector.Accounts

  @valid_user %{
    email: "testuser@example.com",
    password: "secret123",
    password_confirmation: "secret123"
  }

  describe "password reset tokens" do
    setup do
      {:ok, user} = Accounts.create_user(@valid_user)
      %{user: user}
    end

    test "generate_password_reset_token/1 creates a valid token", %{user: user} do
      token = Accounts.generate_password_reset_token(user)
      assert is_binary(token)
      assert byte_size(token) > 0
    end

    test "verify_password_reset_token/1 accepts valid tokens", %{user: user} do
      token = Accounts.generate_password_reset_token(user)
      assert {:ok, verified_user} = Accounts.verify_password_reset_token(token)
      assert verified_user.id == user.id
      assert verified_user.email == user.email
    end

    test "verify_password_reset_token/1 rejects invalid tokens" do
      assert {:error, :invalid} = Accounts.verify_password_reset_token("invalid_token")
    end

    test "verify_password_reset_token/1 rejects tokens for non-existent users" do
      # Create a token for a user that doesn't exist in the database
      salt = Application.get_env(:email_collector, :token_salt)
      token = Phoenix.Token.sign(EmailCollectorWeb.Endpoint, salt, "nonexistent@example.com")
      assert {:error, :not_found} = Accounts.verify_password_reset_token(token)
    end

    test "verify_password_reset_token/1 rejects expired tokens", %{user: user} do
      # Create a token with a very short expiration time
      salt = Application.get_env(:email_collector, :token_salt)
      token = Phoenix.Token.sign(EmailCollectorWeb.Endpoint, salt, user.email)

      # Verify with max_age: 0 to simulate immediate expiration
      assert {:error, :expired} =
               Phoenix.Token.verify(EmailCollectorWeb.Endpoint, salt, token, max_age: 0)
    end
  end
end
