Dynamo.under_test(Exblog.Dynamo)
Dynamo.Loader.enable
ExUnit.start

defmodule Exblog.TestCase do
  use ExUnit.CaseTemplate

  # Enable code reloading on test cases
  setup do
    Dynamo.Loader.enable
    :ok
  end
end
