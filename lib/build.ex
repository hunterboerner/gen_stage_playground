defmodule GenStagePlayground.Build do
  use Ecto.Schema
  import Ecto.Changeset
  alias GenStagePlayground.Build

  schema "builds" do
    field :machine_id, :string
    field :message, :string
    field :status, :string, default: "queued"
  end

  def changeset(build = %Build{}, params \\ %{}) do
    cast(build, params, [:machine_id, :message, :status])
  end
end
