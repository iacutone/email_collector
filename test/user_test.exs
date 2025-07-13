defmodule EmailCollector.UserTest do
  use EmailCollector.DataCase, async: true

  alias EmailCollector.Accounts

  describe "user creation" do
    test "creates a user with hashed password and api_key" do
      attrs = %{
        email: "test@example.com",
        password: "secret123",
        password_confirmation: "secret123"
      }

      {:ok, user} = Accounts.create_user(attrs)
      assert user.email == "test@example.com"
      assert user.password_hash != nil
      assert user.api_key != nil
    end

    test "api_key is unique" do
      attrs1 = %{email: "a@example.com", password: "pw1234", password_confirmation: "pw1234"}
      attrs2 = %{email: "b@example.com", password: "pw5678", password_confirmation: "pw5678"}
      {:ok, user1} = Accounts.create_user(attrs1)
      {:ok, user2} = Accounts.create_user(attrs2)
      assert user1.api_key != user2.api_key
    end
  end
end
