defmodule EmailCollector.Emails do
  @moduledoc """
  The Emails context.
  """

  import Ecto.Query, warn: false
  alias EmailCollector.Repo
  alias EmailCollector.Emails.Email

  @doc """
  Returns the list of emails.
  """
  def list_emails do
    Repo.all(Email)
  end

  @doc """
  Gets a single email.
  """
  def get_email!(id), do: Repo.get!(Email, id)

  @doc """
  Creates a email.
  """
  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a email.
  """
  def update_email(%Email{} = email, attrs) do
    email
    |> Email.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a email.
  """
  def delete_email(%Email{} = email) do
    Repo.delete(email)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email changes.
  """
  def change_email(%Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs)
  end

  @doc """
  Gets emails for a specific user.
  """
  def list_emails_by_user(user_id) do
    Email
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets emails for a specific campaign.
  """
  def list_emails_by_campaign(campaign_id) do
    Email
    |> where(campaign_id: ^campaign_id)
    |> Repo.all()
  end

  @doc """
  Counts emails for a specific campaign.
  """
  def count_emails_by_campaign(campaign_id) do
    Email
    |> where(campaign_id: ^campaign_id)
    |> Repo.aggregate(:count, :id)
  end
end
