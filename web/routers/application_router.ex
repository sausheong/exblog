defmodule ApplicationRouter do
  use Dynamo.Router
  @config Exblog.Dynamo.config
  import Exblog.DBServer, only: [get_posts: 0]
  
  prepare do
    # Pick which parts of the request you want to fetch
    # You can comment the line below if you don't need
    # any of them or move them to a forwarded router
    conn = conn.assign :layout, "main"
    conn = conn.fetch([:session, :cookies, :params])    
    conn.assign(:user, get_session(conn, :user))
  end

  # It is common to break your Dynamo in many
  # routers forwarding the requests between them
  
  get "/" do
    posts = get_posts
    conn = conn.assign(:posts, posts)
    render conn, "index.html"
  end
  
  forward "/post", to: PostsRouter
  forward "/comment", to: CommentsRouter
  
  get "/auth" do
    redirect conn, to: "https://www.facebook.com/dialog/oauth?" <>
                       "client_id=#{@config[:facebook][:app_id]}&" <>
                       "redirect_uri=#{@config[:facebook][:callback_url]}"
  end
  
  get "/auth/callback" do
    response = HTTPotion.get("https://graph.facebook.com/oauth/access_token?" <>
                             "client_id=#{@config[:facebook][:app_id]}&" <>
                             "client_secret=#{@config[:facebook][:secret]}&" <>
                             "redirect_uri=#{@config[:facebook][:callback_url]}&" <>
                             "code=#{conn.params['code']}")

    [at, _] = String.split(response.body, "&")
    [_, token] = String.split(at, "=")
    user = HTTPotion.get("https://graph.facebook.com/me?" <> 
                         "access_token=#{token}&fields=picture,name,username,link")
    user_json = Jsonex.decode user.body
    [{"name", name}, {"username", _username}, {"link", link}, {"id", id}, {"picture", picture}] = user_json
    [{"data", [{"url", url}, _]}] = picture
    user = User.new user_name: name, user_facebook_id: id, user_link: link, user_pic_url: url
    conn = put_session(conn, :user, user)
    redirect conn, to: "/"
  end
  
  get "/signout" do    
    conn = delete_session(conn, :user)
    redirect conn, to: "/"
  end
  
  get "/not_loggedin" do
    render conn, "not_loggedin.html"
  end
  
end
