use Mix.Config

config :gen_stage_playground, GenStagePlayground.Repo,
  pool: Ecto.Adapters.SQL.Sandbox
