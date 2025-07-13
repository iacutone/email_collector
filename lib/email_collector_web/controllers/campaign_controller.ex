defmodule EmailCollectorWeb.CampaignController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  # Define CSV dumper for email data
  NimbleCSV.define(CampaignEmailCSV, separator: ",", escape: "\"")

  def new(conn, _params) do
    user = conn.assigns.current_user

    if user do
      changeset = Campaigns.change_campaign(%Campaigns.Campaign{})
      render(conn, :new, changeset: changeset)
    else
      conn
      |> put_flash(:error, "You must be logged in to create campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def create(conn, %{"campaign" => campaign_params}) do
    user = conn.assigns.current_user

    if user do
      campaign_params = Map.put(campaign_params, "user_id", user.id)

      case Campaigns.create_campaign(campaign_params) do
        {:ok, campaign} ->
          conn
          |> put_flash(:info, "Campaign created successfully")
          |> redirect(to: ~p"/campaigns/#{campaign.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to create campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    if user do
      campaign = Campaigns.get_campaign!(id)

      if campaign.user_id == user.id do
        emails = Emails.list_emails_by_campaign(id)
        render(conn, :show, campaign: campaign, emails: emails)
      else
        conn
        |> put_flash(:error, "Campaign not found")
        |> redirect(to: ~p"/profile")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to view campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def edit(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    if user do
      campaign = Campaigns.get_campaign!(id)

      if campaign.user_id == user.id do
        changeset = Campaigns.change_campaign(campaign)
        render(conn, :edit, campaign: campaign, changeset: changeset)
      else
        conn
        |> put_flash(:error, "Campaign not found")
        |> redirect(to: ~p"/profile")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to edit campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def update(conn, %{"id" => id, "campaign" => campaign_params}) do
    user = conn.assigns.current_user

    if user do
      campaign = Campaigns.get_campaign!(id)

      if campaign.user_id == user.id do
        case Campaigns.update_campaign(campaign, campaign_params) do
          {:ok, campaign} ->
            conn
            |> put_flash(:info, "Campaign updated successfully")
            |> redirect(to: ~p"/campaigns/#{campaign.id}")

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :edit, campaign: campaign, changeset: changeset)
        end
      else
        conn
        |> put_flash(:error, "Campaign not found")
        |> redirect(to: ~p"/profile")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to update campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    if user do
      campaign = Campaigns.get_campaign!(id)

      if campaign.user_id == user.id do
        case Campaigns.delete_campaign(campaign) do
          {:ok, _campaign} ->
            conn
            |> put_flash(:info, "Campaign deleted successfully")
            |> redirect(to: ~p"/profile")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to delete campaign")
            |> redirect(to: ~p"/campaigns/#{campaign.id}")
        end
      else
        conn
        |> put_flash(:error, "Campaign not found")
        |> redirect(to: ~p"/profile")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to delete campaigns")
      |> redirect(to: ~p"/auth/login")
    end
  end

  def download_csv(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    if user do
      # Verify campaign belongs to user
      campaign = Campaigns.get_campaign!(id)

      if campaign.user_id == user.id do
        emails = Emails.list_emails_by_campaign(id)
        csv_content = build_campaign_csv_content(campaign, emails)

        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"campaign_#{campaign.name}_#{Date.utc_today()}.csv\""
        )
        |> send_resp(200, csv_content)
      else
        conn
        |> put_flash(:error, "Campaign not found")
        |> redirect(to: ~p"/profile")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to download data")
      |> redirect(to: ~p"/auth/login")
    end
  end

  defp build_campaign_csv_content(campaign, emails) do
    headers = ["Campaign Name", "Email Name", "Created At"]

    rows =
      Enum.map(emails, fn email ->
        [
          campaign.name,
          email.name,
          format_datetime(email.inserted_at)
        ]
      end)

    [headers | rows]
    |> CampaignEmailCSV.dump_to_iodata()
    |> IO.iodata_to_binary()
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end
