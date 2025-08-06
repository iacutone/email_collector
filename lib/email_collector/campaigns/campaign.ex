defmodule EmailCollector.Campaigns.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "campaigns" do
    field :name, :string
    belongs_to :user, EmailCollector.Accounts.User
    has_many :emails, EmailCollector.Emails.Email

    timestamps()
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint([:user_id, :name])
  end
end
