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
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:campaign_id)
  end
end
