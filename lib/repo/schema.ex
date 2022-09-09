defmodule ExAudit.Schema do
  # def insert_all(module, name, schema_or_source, entries, tuplet = {_adapter_meta, opts}) do
  #   # TODO!
  #   opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)
  #   Ecto.Repo.Schema.insert_all(module, name, schema_or_source, entries, tuplet)
  # end

  def insert(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.insert(module, name, struct, tuplet)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :created, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def update(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.update(module, name, struct, tuplet)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :updated, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def insert_or_update(module, name, changeset, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.insert_or_update(module, name, changeset, tuplet)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(
            module,
            :insert_or_update,
            changeset,
            resulting_struct,
            opts
          )

        _ ->
          :ok
      end

      result
    end)
  end

  def delete(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(module, fn ->
      ExAudit.Tracking.track_assoc_deletion(module, struct, opts)
      result = Ecto.Repo.Schema.delete(module, name, struct, tuplet)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :deleted, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def insert!(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.insert!(module, name, struct, tuplet)
        ExAudit.Tracking.track_change(module, :created, struct, result, opts)
        result
      end,
      true
    )
  end

  def update!(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.update!(module, name, struct, tuplet)
        ExAudit.Tracking.track_change(module, :updated, struct, result, opts)
        result
      end,
      true
    )
  end

  def insert_or_update!(module, name, changeset, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.insert_or_update!(module, name, changeset, tuplet)
        ExAudit.Tracking.track_change(module, :insert_or_update, changeset, result, opts)
        result
      end,
      true
    )
  end

  def delete!(module, name, struct, tuplet = {_adapter_meta, opts}) do
    opts = ExAudit.Tracking.AdditionalData.merge_opts(opts)

    augment_transaction(
      module,
      fn ->
        ExAudit.Tracking.track_assoc_deletion(module, struct, opts)
        result = Ecto.Repo.Schema.delete!(module, name, struct, tuplet)
        ExAudit.Tracking.track_change(module, :deleted, struct, result, opts)
        result
      end,
      true
    )
  end

  # Cleans up the return value from repo.transaction
  defp augment_transaction(repo, fun, bang \\ false) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:main, __MODULE__, :run_in_multi, [fun, bang])

    case {repo.transaction(multi), bang} do
      {{:ok, %{main: value}}, false} -> {:ok, value}
      {{:ok, %{main: value}}, true} -> value
      {{:error, :main, error, _}, false} -> {:error, error}
      {{:error, :main, error, _}, true} -> raise error
    end
  end

  def run_in_multi(_repo, _multi, fun, bang) do
    case {fun.(), bang} do
      {{:ok, _} = ok, false} -> ok
      {{:error, _} = error, false} -> error
      {value, true} -> {:ok, value}
    end
  end
end
