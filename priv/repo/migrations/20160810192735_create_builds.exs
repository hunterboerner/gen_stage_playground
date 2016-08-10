defmodule GenStagePlayground.Repo.Migrations.CreateBuilds do
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :machine_id, :string
      add :message, :string
      add :status, :string, default: "queued"
    end
  end
end
