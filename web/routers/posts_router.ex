defmodule PostsRouter do
  use Dynamo.Router
  import Exblog.Helper, only: [require_login: 1]
  import Exblog.DBServer, only: [add_post: 3, update_post: 3, get_post: 1, delete_post: 1, get_comments: 1]
  
  @prepare :require_login
  get "/new" do
    conn = conn.assign(:post, Post.new)
    render conn, "post.new.html"
  end
  
  @prepare :require_login
  get "/edit/:uuid" do
    post = get_post(conn.params[:uuid])
    conn = conn.assign(:post, post)
    render conn, "post.edit.html"
  end
  
  @prepare :require_login
  post "/" do
    user = get_session(conn, :user)
    uuid = add_post(conn.params[:heading], conn.params[:content], user)
    redirect conn, to: "/post/#{uuid}"
  end

  @prepare :require_login
  post "/update" do
    user = get_session(conn, :user)
    post = get_post(conn.params[:uuid])
    if post.user == user do           
      uuid = update_post(conn.params[:uuid], conn.params[:heading], conn.params[:content])
      redirect conn, to: "/post/#{uuid}"
    else
      render conn, "unauthorized.html"
    end
  end

  @prepare :require_login
  get "/delete/:uuid" do
    user = get_session(conn, :user)
    post = get_post(conn.params[:uuid])
    if post.user == user do
      delete_post(conn.params[:uuid])
      redirect conn, to: "/"
    else
      render conn, "unauthorized.html"
    end
  end
  
  get "/:uuid" do
    post = get_post(conn.params[:uuid])
    conn = conn.assign(:post, post)
  
    comments = get_comments(conn.params[:uuid])
    conn = conn.assign(:comments, comments)
    conn = conn.assign(:comment, Comment.new)
    render conn, "post.html"
  end

end