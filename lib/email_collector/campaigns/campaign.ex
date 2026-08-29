defmodule EmailCollector.Campaigns.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "campaigns" do
    field :name, :string
    field :allowed_origins, {:array, :string}, default: []
    belongs_to :user, EmailCollector.Accounts.User
    has_many :emails, EmailCollector.Emails.Email

    timestamps()
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :user_id, :allowed_origins])
    |> validate_required([:name, :user_id])
    |> validate_origins(:allowed_origins)
    |> unique_constraint([:user_id, :name])
  end

  defp validate_origins(changeset, field) do
    validate_change(changeset, field, fn field, origins ->
      invalid =
        origins
        |> Enum.reject(&valid_origin?/1)

      if Enum.empty?(invalid) do
        []
      else
        [{field, "contains invalid origins: #{Enum.join(invalid, ", ")}"}]
      end
    end)
  end

  defp valid_origin?(origin) do
    uri = URI.parse(origin)
    uri.scheme in ["http", "https"] and not is_nil(uri.host) and uri.host != ""
  end
end
