defmodule ExAudit do
  use Application

  @spec tracked_schemas :: list(module())
  def tracked_schemas do
    Application.fetch_env!(:ex_audit, :tracked_schemas)
  end

  @spec version_schema :: module()
  def version_schema do
    Application.fetch_env!(:ex_audit, :version_schema)
  end

  @spec primitive_structs :: list(module())
  def primitive_structs do
    Application.get_env(:ex_audit, :primitive_structs, [])
  end

  @spec ignored_fields :: list(atom())
  def ignored_fields do
    Application.get_env(:ex_audit, :ignored_fields, []) ++ [:__meta__, :__struct__]
  end

  @doc """
    Indicates if a module should be tracked.

    Can be overwritten for custom tracking logic.
    E.g.
    ```
      def tracked?(struct_or_changeset) do
        %{force_tracking: force_tracking} = struct_or_changeset
        force_tracking && super(struct_or_changeset)
      end
    ```
  """
  @spec tracked?(any) :: boolean
  def tracked?(%Ecto.Changeset{data: %struct{}}), do: tracked?(struct)
  def tracked?(%struct{}), do: tracked?(struct)
  def tracked?(struct), do: struct in tracked_schemas()
  defoverridable(tracked?: 1)

  @doc """
    Adds data to the current process as supplemental data for the
    audit log
  """
  def additional_data(data) do
    ExAudit.Tracking.AdditionalData.track(self(), data)
  end

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(ExAudit.Tracking.AdditionalData, [])
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
