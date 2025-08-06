defmodule EmailCollector.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :subscribed, :boolean, default: true
      add :misc, :json

      timestamps()
    end

    create index(:emails, [:user_id])
    create index(:emails, [:campaign_id])
    create unique_index(:emails, [:campaign_id, :name])
  end
end
