defmodule EmailCollector.CampaignsTest do
  use EmailCollector.DataCase

  alias EmailCollector.Campaigns
  alias EmailCollector.Accounts

  describe "campaigns" do
    setup do
      {:ok, user} =
        Accounts.create_user(%{
          email: "c@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      %{user: user}
    end

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
end
