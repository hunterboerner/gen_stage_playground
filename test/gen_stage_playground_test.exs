defmodule GenStagePlaygroundTest do
  use ExUnit.Case, async: false
  doctest GenStagePlayground

  alias GenStagePlayground.{Build, Repo}
  alias Experimental.GenStage
  import Ecto.Query

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  end

  test "creating a build" do
    %Build{}
    |> Build.changeset(%{machine_id: "theron", message: "Hello"})
    |> Repo.insert!
  end

  test "producing a build marks it running" do
    builds = for n <- 0..5 do
      %Build{}
      |> Build.changeset(%{machine_id: "theron", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    {:ok, a} = GenStage.start_link(GenStagePlayground.BuildProducer, {"theron", 0})
    {:ok, c} = GenStage.start_link(FakeConsumer, :ok)
    GenStage.sync_subscribe(c, to: a)
    :timer.sleep(500)

    refute Repo.get_by(Build, status: "queued")
    assert Repo.one(from b in Build, where: b.status == "running", select: count(b.id)) == 6
  end

  test "consuming a build marks it complete" do
    builds = for n <- 0..5 do
      %Build{}
      |> Build.changeset(%{machine_id: "theron", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    {:ok, a} = GenStage.start_link(GenStagePlayground.BuildProducer, {"theron", 0})
    {:ok, c} = GenStage.start_link(GenStagePlayground.BuildConsumer, :ok)
    GenStage.sync_subscribe(c, to: a, max_demand: 2)
    :timer.sleep(500)

    assert Repo.one(from b in Build, where: b.status == "completed", select: count(b.id)) == 6
  end

  test "Two machines" do
    builds = for n <- 0..10 do
      %Build{}
      |> Build.changeset(%{machine_id: "theron", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    builds = for n <- 0..10 do
      %Build{}
      |> Build.changeset(%{machine_id: "bob", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    {:ok, a} = GenStage.start_link(GenStagePlayground.BuildProducer, {"theron", 0})
    {:ok, c} = GenStage.start_link(GenStagePlayground.BuildConsumer, :ok)
    GenStage.sync_subscribe(c, to: a, max_demand: 2)
    :timer.sleep(1000)

    assert Repo.one(from b in Build,
      where: b.status == "completed" and b.machine_id == "theron",
      select: count(b.id)) == 11
  end

  test "Two consumers, different machines" do
    builds = for n <- 0..10 do
      %Build{}
      |> Build.changeset(%{machine_id: "theron", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    builds = for n <- 0..10 do
      %Build{}
      |> Build.changeset(%{machine_id: "bob", message: "Hello Number: #{n}"})
      |> Repo.insert!
    end

    {:ok, a} = GenStage.start_link(GenStagePlayground.BuildProducer, {"theron", 0})
    {:ok, b} = GenStage.start_link(GenStagePlayground.BuildProducer, {"bob", 0})
    {:ok, c} = GenStage.start_link(GenStagePlayground.BuildConsumer, :ok)
    {:ok, d} = GenStage.start_link(GenStagePlayground.BuildConsumer, :ok)
    GenStage.sync_subscribe(c, to: a, max_demand: 2)
    GenStage.sync_subscribe(d, to: b, max_demand: 2)
    :timer.sleep(2000)

    assert Repo.one(from b in Build,
      where: b.status == "completed",
      select: count(b.id)) == 22
  end

end

defmodule FakeConsumer do
  use Experimental.GenStage

  def init(:ok) do
    {:consumer, :the_state_does_not_matter}
  end

  def handle_events(events, _from, state) do
    # Wait for a second.

    # Inspect the events.
    IO.inspect(events)

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end
end
