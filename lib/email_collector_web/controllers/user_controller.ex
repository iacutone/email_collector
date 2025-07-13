defmodule EmailCollectorWeb.UserController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  def show(conn, _params) do
    user = conn.assigns.current_user

    if user do
      # Get all campaigns for the user with email counts
      campaigns = Campaigns.list_campaigns_by_user(user.id)

      campaigns_with_counts =
        Enum.map(campaigns, fn campaign ->
          email_count = Emails.count_emails_by_campaign(campaign.id)
          Map.put(campaign, :email_count, email_count)
        end)

      render(conn, :show, user: user, campaigns: campaigns_with_counts)
    else
      conn
      |> put_flash(:error, "You must be logged in to view your profile")
      |> redirect(to: ~p"/auth/login")
    end
  end
end
