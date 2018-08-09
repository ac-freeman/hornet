defmodule Hornet.DeepMapElement do
  @enforce_keys [:name, :type, :required?]
  defstruct [:name, :type, :children, :required?, empty?: true]
end
