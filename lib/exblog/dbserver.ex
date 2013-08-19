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
    uuid = :ossp_uuid.make(:v4, :text)
    post = Post.new id: uuid, created_at: :calendar.local_time(), heading: heading, content: content, user: user    
    :mnesia.transaction(fn -> :mnesia.write(post) end)    
    {:reply, uuid, nil}
  end

  @doc """
  Updates a post
  """
  def handle_call({:update_post, uuid, heading, content}, _from, _state) do
    {:atomic, [post | _ ]} = :mnesia.transaction(fn -> :mnesia.read(Post, uuid) end)   
    post = post.update(heading: heading, content: content)
    :mnesia.transaction(fn -> :mnesia.write(post) end)
    {:reply, uuid, nil}
  end

  @doc """
  Returns a post given a uuid
  """
  def handle_call({:get_post, uuid}, _from, _state) do 
    {:atomic, [post | _ ]} = :mnesia.transaction(fn -> :mnesia.read(Post, uuid) end)
    {:reply, post, nil}    
  end
  
  @doc """
  Deletes a post
  """
  def handle_call({:delete_post, uuid}, _from, _state) do
    f = fn -> 
      :mnesia.delete({Post, uuid}) 
      {:atomic, comments} = get_comments(uuid)
      lc comment inlist comments do
        :mnesia.delete({Comment, comment.id}) 
      end
    end
    :mnesia.transaction(f)
    {:reply, "ok", nil}
  end


  @doc """
  Gets all posts and sorts them according to date created
  """
  def handle_call({:get_posts}, _from, _state) do    
    {:atomic, posts} = :mnesia.transaction(fn -> :mnesia.table(Post) |> :qlc.eval end)
    order = fn(a, b) -> a.created_at > b.created_at end
    posts = :lists.sort(order, posts)
    {:reply, posts, nil}    
  end

  @doc """
  Adds a new comment to a post
  """
  def handle_call({:add_comment, post_id, content, user}, _from, _state) do
    uuid = :ossp_uuid.make(:v4, :text)
    comment = Comment.new id: uuid, created_at: :calendar.local_time(), content: content, user: user, post_id: post_id    
    :mnesia.transaction(fn -> :mnesia.write(comment) end)
    {:reply, uuid, nil}
  end

  @doc """
  Get all comments for a post
  """
  def handle_call({:get_comments, uuid}, _from, _state) do
    f = fn -> 
      pattern = Comment[post_id: uuid, _: :_]
      :mnesia.match_object(Comment, pattern, :read) 
    end        
    {:atomic, comments} = :mnesia.transaction(f)
    order = fn(a, b) -> a.created_at > b.created_at end
    comments = :lists.sort(order, comments)
    {:reply, comments, nil}    
  end

  @doc """
  Updates a comment
  """
  def handle_call({:update_comment, uuid, content}, _from, _state) do
    {:atomic, [comment | _ ]} = :mnesia.transaction(fn -> :mnesia.read(Comment, uuid) end)
    comment = comment.update(content: content)
    :mnesia.transaction(fn -> :mnesia.write(comment) end)
    {:reply, uuid, nil}
  end

  @doc """
  Deletes a comment
  """
  def handle_call({:delete_comment, uuid}, _from, _state) do
    :mnesia.transaction(fn -> :mnesia.delete({Comment, uuid}) end)
    {:reply, "ok", nil}
  end

  @doc """
  Returns a comment given a uuid
  """
  def handle_call({:get_comment, uuid}, _from, _state) do
    {:atomic, [comment | _ ]} = :mnesia.transaction(fn -> :mnesia.read(Comment, uuid) end)
    {:reply, comment, nil}    
  end

  # -- interfaces for managing posts

  def add_post(heading, content, user) do 
    :gen_server.call(:dbserver, {:add_post, heading, content, user})
  end

  def update_post(uuid, heading, content) do 
    :gen_server.call(:dbserver, {:update_post, uuid, heading, content})
  end

  def get_post(uuid) do
    :gen_server.call(:dbserver, {:get_post, uuid})
  end

  def delete_post(uuid) do 
    :gen_server.call(:dbserver, {:delete_post, uuid})
  end

  def get_posts do
    posts = :gen_server.call(:dbserver, {:get_posts})
  end

  # -- interfaces for managing comments 

  def add_comment(post_id, content, user) do 
    :gen_server.call(:dbserver, {:add_comment, post_id, content, user})
  end

  def get_comments(uuid) do
    :gen_server.call(:dbserver, {:get_comments, uuid})
  end  

  def update_comment(uuid, content) do 
    :gen_server.call(:dbserver, {:update_comment, uuid, content})
  end

  def delete_comment(uuid) do 
    :gen_server.call(:dbserver, {:delete_comment, uuid})
  end

  def get_comment(uuid) do
    :gen_server.call(:dbserver, {:get_comment, uuid})
  end

end
