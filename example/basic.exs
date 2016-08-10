alias Experimental.GenStage
alias GenStagePlayground.{Build, Repo}
{:ok, a} = GenStage.start_link(GenStagePlayground.BuildProducer, 0)
{:ok, c} = GenStage.start_link(GenStagePlayground.BuildConsumer, :ok)
GenStage.sync_subscribe(c, to: a)
:timer.sleep(:infinity)
