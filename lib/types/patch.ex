defmodule ExAudit.Types.Patch do
  use Ecto.Type

  @type t() :: ExAudit.Diff.changes()

  def cast(a), do: {:ok, a}
  def dump(patch), do: {:ok, :erlang.term_to_binary(patch)}
  def load(binary), do: {:ok, :erlang.binary_to_term(binary)}
  def type, do: :binary
end
