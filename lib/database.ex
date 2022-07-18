defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"
  @num_workers 3

  def start do
    IO.puts("Starting database server.")
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)
    {:ok, start_workers()}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _, workers) do
    worker_key = :erlang.phash2(key, @num_workers)
    {:reply, Map.get(workers, worker_key), workers}
  end

  defp choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  defp start_workers() do
    1..@num_workers
    |> Enum.into(%{}, &start_worker/1)
  end

  @spec start_worker(worker_no :: integer) :: {integer, pid}
  defp start_worker(worker_no) when is_integer(worker_no) do
    {:ok, pid} = Todo.DatabaseWorker.start(@db_folder)
    {worker_no - 1, pid}
  end
end
