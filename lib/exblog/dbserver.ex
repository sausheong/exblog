defrecord User, user_name: "", user_link: "", user_facebook_id: "", user_pic_url: ""
defrecord Comment, id: "", created_at: "", content: nil, post_id: nil, user: nil
defrecord Post, id: "", created_at: nil, heading: nil, content: nil, user: nil

defmodule Exblog.DBServer do
  use GenServer.Behaviour 

  def start(_type, _args) do    
    {:ok, :dbserver}
  end

  def init(_args) do
    setup()
    :mnesia.start()  
    {:ok, "initialized"}
  end
  
  def start_link(args) do
    :gen_server.start_link({:local, :dbserver}, __MODULE__, args, [] )    
  end
  
  def setup do
    :mnesia.create_schema([node()])  
    :mnesia.create_table(Comment, [{:disc_copies, [node()]}, {:attributes,Dict.keys(Comment.__record__(:fields))}, {:type, :ordered_set}])
    :mnesia.create_table(Post, [{:disc_copies, [node()]}, {:attributes,Dict.keys(Post.__record__(:fields))}, {:type, :ordered_set}])
  end
  
  @doc """
  Adds a new post
  """
  def handle_call({:add_post, heading, content, user}, _from, _state) do
    uuid = add_post(heading, content, user)
    {:reply, uuid, nil}
  end

  defp add_post(heading, content, user) do 
    uuid = :ossp_uuid.make(:v4, :text)
    post = Post.new id: uuid, created_at: :calendar.local_time(), heading: heading, content: content, user: user    
    :mnesia.transaction(fn -> :mnesia.write(post) end)
    uuid
  end

  @doc """
  Updates a post
  """
  def handle_call({:update_post, uuid, heading, content}, _from, _state) do
    uuid = update_post(uuid, heading, content)
    {:reply, uuid, nil}
  end

  defp update_post(uuid, heading, content) do 
    {:atomic, [post | _ ]} = get_post(uuid)    
    post = post.update(heading: heading, content: content)
    :mnesia.transaction(fn -> :mnesia.write(post) end)
    uuid
  end

  @doc """
  Deletes a post
  """
  def handle_call({:delete_post, uuid}, _from, _state) do
    delete_post(uuid)
    {:reply, "ok", nil}
  end

  defp delete_post(uuid) do 
    f = fn -> 
      :mnesia.delete({Post, uuid}) 
      {:atomic, comments} = get_comments(uuid)
      lc comment inlist comments do
        :mnesia.delete({Comment, comment.id}) 
      end
    end
    :mnesia.transaction(f)
  end
  
  @doc """
  Returns a post given a uuid
  """
  def handle_call({:get_post, uuid}, _from, _state) do    
    {:reply, get_post(uuid), nil}    
  end

  defp get_post(uuid) do
    {:atomic, [post | _ ]} = :mnesia.transaction(fn -> :mnesia.read(Post, uuid) end)
    post
  end


  @doc """
  Gets all posts and sorts them according to date created
  """
  def handle_call({:get_posts}, _from, _state) do
    {:atomic, posts} = get_posts
    order = fn(a, b) -> a.created_at > b.created_at end
    posts = :lists.sort(order, posts)
    {:reply, posts, nil}    
  end

  defp get_posts do
    f = fn -> :mnesia.table(Post) |> :qlc.eval end
    :mnesia.transaction(f)
  end
  
  @doc """
  Adds a new comment to a post
  """
  def handle_call({:add_comment, post_id, content, user}, _from, _state) do
    uuid = add_comment(post_id, content, user)
    {:reply, uuid, nil}
  end

  defp add_comment(post_id, content, user) do 
    uuid = :ossp_uuid.make(:v4, :text)
    comment = Comment.new id: uuid, created_at: :calendar.local_time(), content: content, user: user, post_id: post_id    
    :mnesia.transaction(fn -> :mnesia.write(comment) end)
    uuid
  end

  @doc """
  Get all comments for a post
  """
  def handle_call({:get_comments, uuid}, _from, _state) do
    {:atomic, comments} = get_comments(uuid)
    order = fn(a, b) -> a.created_at > b.created_at end
    comments = :lists.sort(order, comments)
    {:reply, comments, nil}    
  end

  defp get_comments(uuid) do
    f = fn -> 
      pattern = Comment[post_id: uuid, _: :_]
      :mnesia.match_object(Comment, pattern, :read) 
    end
    :mnesia.transaction(f)
  end  

  @doc """
  Updates a comment
  """
  def handle_call({:update_comment, uuid, content}, _from, _state) do
    uuid = update_comment(uuid, content)
    {:reply, uuid, nil}
  end

  defp update_comment(uuid, content) do 
    {:atomic, [comment | _ ]} = get_comment(uuid)
    comment = comment.update(content: content)
    :mnesia.transaction(fn -> :mnesia.write(comment) end)
    uuid
  end

  @doc """
  Deletes a comment
  """
  def handle_call({:delete_comment, uuid}, _from, _state) do
    delete_comment(uuid)
    {:reply, "ok", nil}
  end

  defp delete_comment(uuid) do 
    :mnesia.transaction(fn -> :mnesia.delete({Comment, uuid}) end)
  end

  @doc """
  Returns a comment given a uuid
  """
  def handle_call({:get_comment, uuid}, _from, _state) do
    {:atomic, [comment | _ ]} = get_comment(uuid)
    {:reply, comment, nil}    
  end

  defp get_comment(uuid) do
    :mnesia.transaction(fn -> :mnesia.read(Comment, uuid) end)
  end

end
