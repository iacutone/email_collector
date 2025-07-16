defmodule EmailCollectorWeb.AuthController do
  use EmailCollectorWeb, :controller

  alias EmailCollector.Accounts
  alias EmailCollector.Accounts.User
  alias EmailCollector.Mailer

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

  # Password reset request form
  def forgot_password(conn, _params) do
    render(conn, :forgot_password)
  end

  # Handle password reset request and send email
  def send_reset_link(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(email) do
      nil ->
        conn
        |> put_flash(
          :info,
          "If your email is in our system, you will receive a password reset link."
        )
        |> redirect(to: ~p"/auth/forgot-password")

      user ->
        token = Accounts.generate_password_reset_token(user)
        reset_url = ~p"/auth/reset-password/?#{[token: token]}"
        Mailer.send_password_reset_email(user.email, reset_url)

        conn
        |> put_flash(
          :info,
          "If your email is in our system, you will receive a password reset link."
        )
        |> redirect(to: ~p"/auth/forgot-password")
    end
  end

  # Password reset form
  def reset_password(conn, %{"token" => token}) do
    case Accounts.verify_password_reset_token(token) do
      {:ok, user} ->
        changeset = Accounts.change_user(user)
        render(conn, :reset_password, changeset: changeset, token: token)

      _ ->
        conn
        |> put_flash(:error, "The password reset link is invalid or has expired.")
        |> redirect(to: ~p"/auth/forgot-password")
    end
  end

  # Handle password update
  def update_password(conn, %{"token" => token, "user" => user_params}) do
    case Accounts.verify_password_reset_token(token) do
      {:ok, user} ->
        case Accounts.update_user(user, user_params) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "Your password has been reset. Please log in.")
            |> redirect(to: ~p"/auth/login")

          {:error, changeset} ->
            render(conn, :reset_password, changeset: changeset, token: token)
        end

      _ ->
        conn
        |> put_flash(:error, "The password reset link is invalid or has expired.")
        |> redirect(to: ~p"/auth/forgot-password")
    end
  end
end
