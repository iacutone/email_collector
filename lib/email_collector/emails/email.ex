defmodule EmailCollector.Emails.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emails" do
    field :name, :string
    belongs_to :user, EmailCollector.Accounts.User
    belongs_to :campaign, EmailCollector.Campaigns.Campaign

    timestamps()
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [:name, :user_id, :campaign_id])
    |> validate_required([:name, :user_id, :campaign_id])
    |> validate_email(:name)
    |> unique_constraint([:campaign_id, :name],
      message: "An email with this name already exists in this campaign"
    )
  end

  defp validate_email(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      case EmailAddress.parse(value) do
        nil -> [{field, "must be a valid email address"}]
        _ -> []
      end
    end)
  end
end
