defmodule Fskick.EventStore.JsonSerializer do
  @moduledoc """
  JSON serializer that loads the event struct module on demand before
  decoding.

  The default `EventStore.JsonSerializer` calls
  `Jason.decode!(binary, keys: :atoms!)`, which fails when any JSON key
  has not yet been interned as an atom in the VM. Atoms become interned
  when the module that references them is loaded, but BEAM module
  loading is lazy and the `EventStore.Subscriptions.SubscriptionFsm`
  process that runs deserialize/2 is started before any projector's
  `project/3` clause has executed — so on cold boot the first read of a
  fresh event type crashes.

  This serializer calls `Code.ensure_loaded!/1` on the event struct
  module before decoding. The struct's field atoms are interned during
  module load, so the strict-atoms decode always succeeds.
  """

  @behaviour EventStore.Serializer

  @impl true
  def serialize(term) do
    Jason.encode!(term)
  end

  @impl true
  def deserialize(binary, config) do
    case Keyword.get(config, :type) do
      nil ->
        Jason.decode!(binary)

      type ->
        module = String.to_existing_atom(type)
        Code.ensure_loaded!(module)
        struct(module, Jason.decode!(binary, keys: :atoms!))
    end
  end
end
