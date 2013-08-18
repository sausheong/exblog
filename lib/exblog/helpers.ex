defmodule Exblog.Helper do
  use Dynamo.Router
  def require_login(conn) do
    if get_session(conn, :user) == nil do
      redirect conn, to: "/not_loggedin"      
    end
  end  
end
