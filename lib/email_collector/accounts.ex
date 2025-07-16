defmodule EmailCollector.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias EmailCollector.Repo
  alias EmailCollector.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by API key.
  """
  def get_user_by_api_key(api_key) do
    Repo.get_by(User, api_key: api_key)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Authenticates a user by email and password.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    case user do
      nil ->
        {:error, :not_found}

      user ->
        if User.verify_password(user, password) do
          {:ok, user}
        else
          {:error, :invalid_password}
        end
    end
  end

  def generate_password_reset_token(%User{email: email}) do
    salt = Application.get_env(:email_collector, :token_salt)
    Phoenix.Token.sign(EmailCollectorWeb.Endpoint, salt, email)
  end

  def verify_password_reset_token(token) do
    salt = Application.get_env(:email_collector, :token_salt)
    max_age = 3600 # 1 hour
    case Phoenix.Token.verify(EmailCollectorWeb.Endpoint, salt, token, max_age: max_age) do
      {:ok, email} ->
        case get_user_by_email(email) do
          nil -> {:error, :not_found}
          user -> {:ok, user}
        end
      error -> error
    end
  end
end
