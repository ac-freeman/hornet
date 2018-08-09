defmodule Hornet.DeepMap do
  @enforce_keys [:data, :reference]
  defstruct [:data, :reference, valid?: true, errors: []]
end
