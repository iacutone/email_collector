defmodule EmailCollector.Repo.Migrations.AddAllowedOriginsToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :allowed_origins, {:array, :string}, default: []
    end
  end
end
