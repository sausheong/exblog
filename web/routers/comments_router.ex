defmodule CommentsRouter do
  use Dynamo.Router
  import Exblog.Helper, only: [require_login: 1]
  import Exblog.DBServer, only: [add_comment: 3, update_comment: 2, get_comment: 1, delete_comment: 1]
  
  @prepare :require_login
  post "/" do
    user = get_session(conn, :user)
    add_comment(conn.params[:post_id], conn.params[:content], user)
    redirect conn, to: "/post/#{conn.params[:post_id]}"
  end

  @prepare :require_login
  get "/edit/:uuid" do
    comment = get_comment(conn.params[:uuid])
    conn = conn.assign(:comment, comment)
    render conn, "comment.edit.html"
  end

  @prepare :require_login
  post "/update" do
    user = get_session(conn, :user)
    comment = get_comment(conn.params[:uuid])
    if comment.user == user do         
      uuid = update_comment(conn.params[:uuid], conn.params[:content])
      redirect conn, to: "/post/#{comment.post_id}#comment_#{comment.id}"
    else
      render conn, "unauthorized.html"
    end
  end

  @prepare :require_login
  get "/delete/:uuid" do
    user = get_session(conn, :user)
    comment = get_comment(conn.params[:uuid])
    if comment.user == user do         
      delete_comment(conn.params[:uuid])
      redirect conn, to: "/post/#{comment.post_id}"
    else
      render conn, "unauthorized.html"
    end
  end

end