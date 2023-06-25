defmodule Todo.Cache do
  use GenServer
  alias Todo.Database
  alias Todo.Server

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(todo_list_name) do
    GenServer.call(__MODULE__, {:server_process, todo_list_name})
  end

  def init(_) do
    IO.puts("Starting todo cache")
    Database.start_link()
    {:ok, %{}}
  end

  def handle_call(_request = {:server_process, todo_list_name}, _from = _, _state = todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}

      :error ->
        {:ok, new_server} = Server.start_link(todo_list_name)
        {:reply, new_server, Map.put(todo_servers, todo_list_name, new_server)}
    end
  end
end
