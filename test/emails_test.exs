defmodule EmailCollector.EmailsTest do
  use EmailCollector.DataCase, async: true

  alias EmailCollector.Emails
  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns

  describe "emails" do
    setup do
      {:ok, user} =
        Accounts.create_user(%{
          email: "e@example.com",
          password: "pw1234",
          password_confirmation: "pw1234"
        })

      {:ok, campaign} = Campaigns.create_campaign(%{name: "C1", user_id: user.id})
      %{user: user, campaign: campaign}
    end

    test "creates an email and associates with user and campaign", %{
      user: user,
      campaign: campaign
    } do
      attrs = %{name: "recipient@example.com", user_id: user.id, campaign_id: campaign.id}
      {:ok, email} = Emails.create_email(attrs)
      assert email.name == "recipient@example.com"
      assert email.user_id == user.id
      assert email.campaign_id == campaign.id
    end

    test "retrieves emails by campaign", %{user: user, campaign: campaign} do
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

      emails = Emails.list_emails_by_campaign(campaign.id)
      assert Enum.any?(emails, &(&1.id == email1.id))
      assert Enum.any?(emails, &(&1.id == email2.id))
    end
  end
end
