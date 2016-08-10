# Mix.Task.run "ecto.drop", ["--quiet"]
# Mix.Task.run "ecto.create", ["--quiet"]
# Mix.Task.run "ecto.migrate", ["--quiet"]
Ecto.Adapters.SQL.Sandbox.mode(GenStagePlayground.Repo, :manual)
ExUnit.start()
