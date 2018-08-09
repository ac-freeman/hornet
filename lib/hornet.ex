defmodule Hornet do
  alias Hornet.DeepMap

  def validate(validator, parent \\ %{})

  def validate(%DeepMap{reference: [head| []], data: data} = validator, parent) when is_map(data) do
    name = head.name
    type = head.type

    validator
    |> __validate_has_key__(head, name, type, parent)
    |> __validate_type__(name, type, parent)
    |> __validate_not_empty__(head, name, type, parent)
    |> validate_children(head, name, parent, head.children)
  end

  def validate(%DeepMap{reference: [head| tail], data: data} = validator, parent) when is_map(data) do
    name = head.name
    type = head.type

    validator
    |> __validate_has_key__(head, name, type, parent)
    |> __validate_type__(name, type, parent)
    |> __validate_not_empty__(head, name, type, parent)
    |> validate_children(head, name, parent, head.children)
    |> Map.put(:reference, tail)
    |> validate(head)
  end

  # This function should only be reached when the initial map being validated is invalid, or when a
  # fetched child is not a valid map like expected
  def validate(%DeepMap{data: _data} = validator, parent) do
    validator
    |> add_error("map", "is invalid", parent, [type: :map, validation: :cast])
  end

  @doc false
  def __validate_type__(%DeepMap{data: data} = validator, name, type, parent) when type == :number do
    with true <- Map.has_key?(data, name),
    :integer <- type_of(Map.get(data, name)) do
      validator
    else
      :float -> validator
      _ -> add_error(validator, name, "is invalid", parent, [type: type, validation: :cast])
    end
  end

  @doc false
  def __validate_type__(%DeepMap{data: data} = validator, name, type, parent) do
    with true <- Map.has_key?(data, name),
      ^type <- type_of(Map.get(data, name)) do

        validator
    else
      _ -> add_error(validator, name, "is invalid", parent, [type: type, validation: :cast])
    end
  end

  @doc false
  def __validate_has_key__(%DeepMap{data: data} = validator, head, name, type, parent) do
    with true <- head.required?,
        false <- Map.has_key?(data, name) do
          add_error(validator, name, "nil", parent, [type: type, validation: :cast])
    else
      _ -> validator
    end
  end

  @doc false
  def __validate_not_empty__(%DeepMap{data: data} = validator, head, name, type, parent) do
    with {:ok, value} <- Map.fetch(data, name),
      :binary <- type_of(value),
      false <- head.empty?,
      0 <- byte_size(value) do
        add_error(validator, name,"can't be blank", parent, [type: type, validation: :cast])
    else
      _ -> validator
    end
  end

  defp validate_children(%DeepMap{data: data, errors: errors} = validator, _head, key, parent, children) when is_tuple(children) do
    with true <- Map.has_key?(data, key),
      {:ok, new_data} <- Map.fetch(data, key) do

      #for each child map in params, validate it with 'children'
      new_errors =
        new_data
        |> Enum.map(fn x ->
            %DeepMap{data: x, reference: Tuple.to_list(children)}
            |> validate(Map.get(parent, key))
            |> Map.get(:errors)
        end)

      errors =
        [errors | new_errors]
        |> List.flatten()
        |> Enum.uniq()

      validator
      |> Map.put(:errors, errors)
    else
      _ -> validator
    end
  end

  defp validate_children(%DeepMap{data: data} = validator, head, key, _parent, children) when is_list(children) do
    with true <- Map.has_key?(data, key),
      {:ok, _new_data} <- Map.fetch(data, key) do
        new_errors = get_child_list_errors(validator, head, data, key, children)
        validator
        |> add_errors(new_errors)
    else
      _ -> validator
    end
  end

  # default if children attribute not specified
  defp validate_children(validator, _head, _key, _parent, children) when children == nil do
    validator
  end

  # default if children attribute is not a valid list or tuple
  defp validate_children(validator, _head, key, parent, _children) do
    validator
    |> add_error(key, "reference children is invalid", parent, [type: "children", validation: :cast])
  end

  defp get_child_list_errors(validator, head, data, key, children) do
    case Map.fetch(data, key) do
      {:ok, new_data} ->
        validator
        |> Map.put(:data, new_data)
        |> Map.put(:reference, children)
        |> validate(head)
        |> Map.get(:errors)

      _ -> validator
          |> Map.get(:errors)
    end
  end

  def get_ecto_errors(%DeepMap{errors: errors}, key) when is_atom(key) do
    errors
    |> Enum.map(fn x ->
      {key, convert_error_for_ecto(x)}
    end)
  end

  defp convert_error_for_ecto({attr, issue, parent, more_info}) do
    attr =
      case type_of(attr) do
        :binary -> attr

        _ ->  stringify(attr)
      end
    parent =
      parent
      |> Keyword.get(:parent)
      |> stringify()
    {attr <> " " <> issue <> ", parent: " <> parent, more_info}
  end

  defp stringify(attr) do
    opts = struct(Inspect.Opts, [])
    doc = Inspect.Algebra.group(Inspect.Algebra.to_doc(attr, opts))
    Inspect.Algebra.format(doc, opts.width)
    |> Enum.join("")
  end

  defp add_error(%DeepMap{errors: errors} = validator, attr, issue, parent, more_info) do
    parent =
      case Map.has_key?(parent, :children) do
        true -> Map.put(parent, :children, nil)
        false -> parent
      end

    message = {attr, issue, [parent: parent], more_info}

    errors =
      [message | errors]
      |> List.flatten()
      |> Enum.uniq()

    validator
    |> Map.put(:errors, errors)
    |> Map.put(:valid?, false)
  end

  defp add_errors(%DeepMap{errors: errors} = validator, new_errors) do
    errors =
      [new_errors | errors]
      |> List.flatten()
      |> Enum.uniq()

    valid =
      case length(new_errors) do
        0 -> true
        _ -> false
      end

    validator
    |> Map.put(:errors, errors)
    |> Map.put(:valid?, valid)
  end

  defp type_of(self) do
    cond do
      is_float(self)    -> :float
      is_integer(self)  -> :integer
      is_boolean(self)  -> :boolean
      is_atom(self)     -> :atom
      is_binary(self)   -> :binary
      is_function(self) -> :function
      is_list(self)     -> :list
      is_map(self)      -> :map
      is_tuple(self)    -> :tuple
      true              -> :unknown_type
    end
  end
end
