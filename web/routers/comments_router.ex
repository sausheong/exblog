defmodule CommentsRouter do
  use Dynamo.Router
  import Exblog.Helper, only: [require_login: 1]

  
  @prepare :require_login
  post "/" do
    user = get_session(conn, :user)
    :gen_server.call(:dbserver, {:add_comment, conn.params[:post_id], conn.params[:content], user})
    redirect conn, to: "/post/#{conn.params[:post_id]}"
  end

  @prepare :require_login
  get "/edit/:uuid" do
    comment = :gen_server.call(:dbserver, {:get_comment, conn.params[:uuid]})
    conn = conn.assign(:comment, comment)
    render conn, "comment.edit.html"
  end

  @prepare :require_login
  post "/update" do
    user = get_session(conn, :user)
    comment = :gen_server.call(:dbserver, {:get_comment, conn.params[:uuid]})
    if comment.user == user do         
      uuid = :gen_server.call(:dbserver, {:update_comment, conn.params[:uuid], conn.params[:content]})
      redirect conn, to: "/post/#{comment.post_id}#comment_#{comment.id}"
    else
      render conn, "unauthorized.html"
    end
  end

  @prepare :require_login
  get "/delete/:uuid" do
    user = get_session(conn, :user)
    comment = :gen_server.call(:dbserver, {:get_comment, uuid})
    if comment.user == user do         
      :gen_server.call(:dbserver, {:delete_comment, conn.params[:uuid]})
      redirect conn, to: "/"
    else
      render conn, "unauthorized.html"
    end
  end

end