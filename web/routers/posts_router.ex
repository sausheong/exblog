defmodule PostsRouter do
  use Dynamo.Router
  import Exblog.Helper, only: [require_login: 1]

  @prepare :require_login
  get "/new" do
    conn = conn.assign(:post, Post.new)
    render conn, "post.new.html"
  end
  
  @prepare :require_login
  get "/edit/:uuid" do
    post = :gen_server.call(:dbserver, {:get_post, conn.params[:uuid]})
    conn = conn.assign(:post, post)
    render conn, "post.edit.html"
  end
  
  @prepare :require_login
  post "/" do
    user = get_session(conn, :user)
    uuid = :gen_server.call(:dbserver, {:add_post, conn.params[:heading], conn.params[:content], user})
    redirect conn, to: "/post/#{uuid}"
  end

  @prepare :require_login
  post "/update" do
    user = get_session(conn, :user)
    post = :gen_server.call(:dbserver, {:get_post, conn.params[:uuid]})
    if post.user == user do     
      uuid = :gen_server.call(:dbserver, {:update_post, conn.params[:uuid], conn.params[:heading], conn.params[:content]})
      redirect conn, to: "/post/#{uuid}"
    else
      render conn, "unauthorized.html"
    end
  end

  @prepare :require_login
  get "/delete/:uuid" do
    user = get_session(conn, :user)
    post = :gen_server.call(:dbserver, {:get_post, conn.params[:uuid]})
    if post.user == user do
      :gen_server.call(:dbserver, {:delete_post, conn.params[:uuid]})
      redirect conn, to: "/"
    else
      render conn, "unauthorized.html"
    end
  end
  
  get "/:uuid" do
    post = :gen_server.call(:dbserver, {:get_post, conn.params[:uuid]})
    conn = conn.assign(:post, post)
  
    comments = :gen_server.call(:dbserver, {:get_comments, conn.params[:uuid]})
    conn = conn.assign(:comments, comments)
    conn = conn.assign(:comment, Comment.new)
    render conn, "post.html"
  end

end