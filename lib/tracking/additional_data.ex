defmodule ExAudit.Tracking.AdditionalData do
  @moduledoc "Additional data used to supplement the audit log"

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    ets = :ets.new(__MODULE__, [:protected, :named_table])
    {:ok, ets}
  end

  @impl GenServer
  def handle_call({:store, pid, data}, _, ets) do
    :ets.insert(ets, {pid, data})
    Process.monitor(pid)
    {:reply, :ok, ets}
  end

  def track(pid, data) do
    GenServer.call(__MODULE__, {:store, pid, data})
  end

  def get(pid \\ self()) do
    :ets.lookup(__MODULE__, pid)
    |> Enum.flat_map(&elem(&1, 1))
  end

  def merge_opts(opts) when is_list(opts), do: opts ++ additional_opts()
  def merge_opts(_), do: additional_opts()

  defp additional_opts do
    case Process.whereis(__MODULE__) do
      nil -> []
      _ -> [ex_audit_additional: get()]
    end
  end
end
