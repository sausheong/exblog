defmodule Exblog.Supervisor do
  use Supervisor.Behaviour
  
  def start_link(args) do
    :supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [ 
      worker(Exblog.DBServer, [args]),
      supervisor(Exblog.Dynamo, []) 
    ]
    supervise children, strategy: :one_for_one
  end  

end