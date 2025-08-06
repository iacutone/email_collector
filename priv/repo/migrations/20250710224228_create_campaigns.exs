defmodule EmailCollector.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns, primary_key: false) do
      add(:id, :binary_id, primary_key: true, null: false)
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:campaigns, [:user_id])
    create unique_index(:campaigns, [:user_id, :name])
  end
end
