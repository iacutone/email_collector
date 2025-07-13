defmodule EmailCollector.Fixtures do
  alias EmailCollector.Accounts
  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  def user_fixture(attrs \\ %{}) do
    default_attrs = %{
      email: "user_#{System.unique_integer()}@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    {:ok, user} = Accounts.create_user(Map.merge(default_attrs, attrs))
    user
  end

  def campaign_fixture(user, attrs \\ %{}) do
    default_attrs = %{
      name: "Campaign #{System.unique_integer()}",
      user_id: user.id
    }

    {:ok, campaign} = Campaigns.create_campaign(Map.merge(default_attrs, attrs))
    campaign
  end

  def email_fixture(user, campaign, attrs \\ %{}) do
    default_attrs = %{
      name: "Email #{System.unique_integer()}",
      user_id: user.id,
      campaign_id: campaign.id
    }

    {:ok, email} = Emails.create_email(Map.merge(default_attrs, attrs))
    email
  end
end
