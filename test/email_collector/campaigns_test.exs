defmodule EmailCollector.CampaignsTest do
  use EmailCollector.DataCase, async: true

  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns

  setup do
    {:ok, user} =
      Accounts.create_user(%{
        email: "campaigns@example.com",
        password: "pw1234",
        password_confirmation: "pw1234"
      })

    %{user: user}
  end

  describe "campaigns" do
    test "creates a campaign and associates with user", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test Campaign", user_id: user.id})
      assert campaign.name == "Test Campaign"
      assert campaign.user_id == user.id
    end

    test "retrieves campaign by id", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})
      found = Campaigns.get_campaign!(campaign.id)
      assert found.id == campaign.id
    end
  end

  describe "allowed_origins" do
    test "defaults to empty list", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})
      assert campaign.allowed_origins == []
    end

    test "can be set at creation time", %{user: user} do
      {:ok, campaign} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["https://myapp.com"]
        })

      assert campaign.allowed_origins == ["https://myapp.com"]
    end

    test "accepts http and https schemes", %{user: user} do
      {:ok, campaign} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["https://myapp.com", "http://localhost:3000"]
        })

      assert "https://myapp.com" in campaign.allowed_origins
      assert "http://localhost:3000" in campaign.allowed_origins
    end

    test "rejects invalid origins", %{user: user} do
      {:error, changeset} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["not-a-url", "ftp://badscheme.com"]
        })

      assert changeset.errors[:allowed_origins] != nil
    end

    test "rejects origin without scheme", %{user: user} do
      {:error, changeset} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["myapp.com"]
        })

      assert changeset.errors[:allowed_origins] != nil
    end
  end

  describe "add_allowed_origin/2" do
    test "adds a new origin", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})

      {:ok, updated} = Campaigns.add_allowed_origin(campaign, "https://myapp.com")
      assert "https://myapp.com" in updated.allowed_origins
    end

    test "adding same origin twice is idempotent", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})

      {:ok, updated1} = Campaigns.add_allowed_origin(campaign, "https://myapp.com")
      {:ok, updated2} = Campaigns.add_allowed_origin(updated1, "https://myapp.com")

      assert Enum.count(updated2.allowed_origins, &(&1 == "https://myapp.com")) == 1
    end

    test "can add multiple distinct origins", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})

      {:ok, updated} = Campaigns.add_allowed_origin(campaign, "https://myapp.com")
      {:ok, updated} = Campaigns.add_allowed_origin(updated, "https://staging.myapp.com")
      {:ok, updated} = Campaigns.add_allowed_origin(updated, "http://localhost:3000")

      assert length(updated.allowed_origins) == 3
    end

    test "rejects invalid origin", %{user: user} do
      {:ok, campaign} = Campaigns.create_campaign(%{name: "Test", user_id: user.id})

      {:error, changeset} = Campaigns.add_allowed_origin(campaign, "not-a-url")
      assert changeset.errors[:allowed_origins] != nil
    end
  end

  describe "remove_allowed_origin/2" do
    test "removes an existing origin", %{user: user} do
      {:ok, campaign} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["https://myapp.com", "https://staging.myapp.com"]
        })

      {:ok, updated} = Campaigns.remove_allowed_origin(campaign, "https://myapp.com")
      refute "https://myapp.com" in updated.allowed_origins
      assert "https://staging.myapp.com" in updated.allowed_origins
    end

    test "removing a non-existent origin is a no-op", %{user: user} do
      {:ok, campaign} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["https://myapp.com"]
        })

      {:ok, updated} = Campaigns.remove_allowed_origin(campaign, "https://nothere.com")
      assert updated.allowed_origins == ["https://myapp.com"]
    end

    test "can remove all origins leaving an empty list", %{user: user} do
      {:ok, campaign} =
        Campaigns.create_campaign(%{
          name: "Test",
          user_id: user.id,
          allowed_origins: ["https://myapp.com"]
        })

      {:ok, updated} = Campaigns.remove_allowed_origin(campaign, "https://myapp.com")
      assert updated.allowed_origins == []
    end
  end
end
