defmodule EmailCollectorWeb.Api.EmailController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Campaigns
  alias EmailCollector.Emails

  def create(conn, %{"campaign_id" => campaign_id, "email" => email_params}) do
    user = conn.assigns.current_user

    # Verify the campaign belongs to the user
    case Campaigns.get_campaign(campaign_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Campaign not found"})

      campaign ->
        if campaign.user_id == user.id do
          # Create the email
          email_attrs = %{
            name: email_params["name"],
            user_id: user.id,
            campaign_id: campaign_id
          }

          case Emails.create_email(email_attrs) do
            {:ok, email} ->
              conn
              |> put_status(:created)
              |> json(%{
                id: email.id,
                name: email.name,
                campaign_id: email.campaign_id,
                inserted_at: email.inserted_at
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Invalid email data", details: format_changeset_errors(changeset)})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Campaign not found or access denied"})
        end
    end
  end

  def index(conn, %{"campaign_id" => campaign_id}) do
    user = conn.assigns.current_user

    case Campaigns.get_campaign(campaign_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Campaign not found"})

      campaign ->
        if campaign.user_id == user.id do
          emails = Emails.list_emails_by_campaign(campaign_id)

          json(
            conn,
            Enum.map(emails, fn email ->
              %{
                id: email.id,
                name: email.name,
                campaign_id: email.campaign_id,
                inserted_at: email.inserted_at
              }
            end)
          )
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Campaign not found or access denied"})
        end
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
