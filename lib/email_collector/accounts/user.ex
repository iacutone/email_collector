defmodule EmailCollector.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bcrypt

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :api_key, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_many :campaigns, EmailCollector.Campaigns.Campaign
    has_many :emails, EmailCollector.Emails.Email

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation])
    |> validate_required([:email, :password, :password_confirmation])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> put_api_key()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp put_api_key(%Ecto.Changeset{valid?: true} = changeset) do
    put_change(changeset, :api_key, generate_api_key())
  end

  defp put_api_key(changeset), do: changeset

  defp generate_api_key do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> binary_part(0, 32)
  end

  def verify_password(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end
end
