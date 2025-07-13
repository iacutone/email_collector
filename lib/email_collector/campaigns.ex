defmodule EmailCollector.Campaigns do
  @moduledoc """
  The Campaigns context.
  """

  import Ecto.Query, warn: false
  alias EmailCollector.Repo
  alias EmailCollector.Campaigns.Campaign

  @doc """
  Returns the list of campaigns.
  """
  def list_campaigns do
    Repo.all(Campaign)
  end

  @doc """
  Gets a single campaign.
  """
  def get_campaign!(id), do: Repo.get!(Campaign, id)

  @doc """
  Gets a single campaign or returns nil if not found.
  """
  def get_campaign(id), do: Repo.get(Campaign, id)

  @doc """
  Creates a campaign.
  """
  def create_campaign(attrs \\ %{}) do
    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a campaign.
  """
  def update_campaign(%Campaign{} = campaign, attrs) do
    campaign
    |> Campaign.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a campaign.
  """
  def delete_campaign(%Campaign{} = campaign) do
    Repo.delete(campaign)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking campaign changes.
  """
  def change_campaign(%Campaign{} = campaign, attrs \\ %{}) do
    Campaign.changeset(campaign, attrs)
  end

  @doc """
  Gets campaigns for a specific user.
  """
  def list_campaigns_by_user(user_id) do
    Campaign
    |> where(user_id: ^user_id)
    |> Repo.all()
  end
end
