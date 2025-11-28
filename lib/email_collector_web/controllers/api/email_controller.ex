defmodule EmailCollectorWeb.Api.EmailController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Campaigns
  alias EmailCollector.Emails
  alias EmailCollectorWeb.RateLimiter

  def create(conn, %{"campaign_id" => campaign_id, "email" => email_params}) do
    # No authentication required for POST
    ip_address = RateLimiter.get_client_ip(conn)

    # Check rate limits
    with {:ok, :allowed} <- RateLimiter.check_ip_rate_limit(ip_address),
         {:ok, :allowed} <- RateLimiter.check_campaign_rate_limit(campaign_id) do
      case Campaigns.get_campaign(campaign_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Campaign not found"})

        campaign ->
          # Create the email for the campaign's user
          email_attrs = %{
            name: email_params["name"],
            user_id: campaign.user_id,
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
      end
    else
      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limit exceeded. Please try again later."})
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

  def unsubscribe(conn, %{"campaign_id" => campaign_id, "email" => email_name}) do
    # No authentication required for unsubscribe
    case Campaigns.get_campaign(campaign_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Campaign not found"})

      _campaign ->
        case Emails.get_email_by_campaign_and_name(campaign_id, email_name) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Email not found in this campaign"})

          email ->
            case Emails.unsubscribe_email(email) do
              {:ok, updated_email} ->
                conn
                |> put_status(:ok)
                |> json(%{
                  message: "Successfully unsubscribed",
                  email: email_name,
                  subscribed: updated_email.subscribed
                })

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{error: "Failed to unsubscribe", details: format_changeset_errors(changeset)})
            end
        end
    end
  end

  def options(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "Content-Type, Authorization, Accept")
    |> send_resp(200, "")
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
