defmodule LiveUi.Runtime.Model do
  @moduledoc """
  Shared runtime state owned by the internal LiveView engine.
  """

  alias LiveUi.Source

  @type status :: :initializing | :ready | :error

  @enforce_keys [:runtime_context, :source]
  defstruct [
    :error,
    :iur_tree,
    :last_event,
    :last_signal,
    :runtime_context,
    :screen_state,
    :source,
    status: :initializing,
    event_count: 0
  ]

  @type t :: %__MODULE__{
          error: Exception.t() | nil,
          iur_tree: term(),
          last_event: map() | nil,
          last_signal: map() | nil,
          runtime_context: map(),
          screen_state: map() | nil,
          source: Source.t(),
          status: status(),
          event_count: non_neg_integer()
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, attrs)
  end
end
