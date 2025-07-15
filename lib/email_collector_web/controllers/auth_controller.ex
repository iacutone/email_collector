defmodule EmailCollectorWeb.AuthController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Accounts
  alias EmailCollector.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: ~p"/profile")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def login(conn, _params) do
    render(conn, :login)
  end

  def authenticate(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/profile")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully!")
    |> redirect(to: ~p"/")
  end
end
