defmodule GenStagePlayground.BuildProducer do
  use Experimental.GenStage
  import Ecto.Query
  alias GenStagePlayground.{Repo, Build}

  @name __MODULE__

  def start_link() do
    GenStage.start_link(__MODULE__, 0, name: @name)
  end

  def init({machine_id, counter}) do
    {:producer, {machine_id, counter}}
  end

  def handle_cast(:enqueued, state) do
    serve_jobs(state)
  end

  def handle_demand(demand, {machine_id, counter}) do
    serve_jobs({machine_id, demand + counter})
  end

  defp serve_jobs(state = {_, 0}) do
    {:noreply, [], state}
  end

  defp serve_jobs({machine_id, limit}) when limit > 0 do
    # cancel previous timer
    {count, events} = take({machine_id, limit})
    timer = Process.send_after(@name, :enqueued, 60_000)
    {:noreply, events, {machine_id, limit - count}}
  end

  defp take({machine_id, limit}) do
    {:ok, {count, builds}} = Repo.transaction fn ->
      ids = Repo.all queued({machine_id, limit})
      Repo.update_all by_ids(ids),
        [set: [status: "running"]],
        [returning: [:id, :machine_id, :message, :status]]
    end
    {count, builds}
  end

  defp by_ids(ids) do
    from b in Build, where: b.id in ^ids
  end

  defp queued({machine_id, limit}) do
    from b in Build,
      where: b.status == "queued",
      where: b.machine_id == ^machine_id,
      # TODO: Filter here
      limit: ^limit,
      select: b.id,
      lock: "FOR UPDATE SKIP LOCKED"
  end
end

defmodule GenStagePlayground.BuildConsumer do
  use Experimental.GenStage
  alias GenStagePlayground.{Repo, Build}

  def init(:ok) do
    {:consumer, :the_state_does_not_matter}
  end

  def handle_events(events, _from, state) do
    for build <- events do
      Task.async fn ->
        build
        |> Build.changeset(%{status: "completed"})
        |> Repo.update
      end
    end
    |> Enum.map(&Task.await/1)

    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end
end
