defmodule Hornet.HornetTest do
  use ExUnit.Case
  alias Hornet.DeepMap
  alias Hornet.DeepMapElement, as: Element

  @test_map %{
    "id" => "a211e016-845e-42be-b7ac-23111f441f7f",
    "dateTime" => "",
    "information" => "This is some stringy information",
    :number => "one",
    {:number, :two} => 2,
    "optional_info" => "",
    "nestedMap" =>
    %{
      "nest" =>
      %{
        "data" => [1,2,3,4,5,6,7,8,9,10],
        :purpose => "To live",
        [:more_data] => [-1,-2,-3,-4,-5]
      }
    }
  }

  @test_map_malformed %{
    "id" => "a211e016-845e-42be-b7ac-23111f441f7f",
    "dateTime" => "",
    "information" => 2,
    :number => "one",
    {:number, :two} => 2,
    "optional_info" => "",
    "nestedMap" =>
    %{
      "nest" =>
      %{
        "data" => "[1,2,3,4,5,6,7,8,9,10]",
        :purpose => "To live",
        [:more_data] => [-1,-2,-3,-4,-5]
      }
    }
  }

  @test_map_reference [
    %Element{name: "id", type: :binary, required?: true, empty?: false},
    %Element{name: "dateTime", type: :binary, required?: true, empty?: true},
    %Element{name: "information", type: :binary, required?: true, empty?: true},
    %Element{name: :number, type: :binary, required?: true, empty?: false},
    %Element{name: {:number, :two}, type: :integer, required?: true},
    %Element{name: "optional_info", type: :binary, required?: false, empty?: true},
    %Element{name: "nestedMap", type: :map, required?: true,
      children: [
        %Element{name: "nest", type: :map, required?: true,
          children: [
            %Element{name: "data", type: :list, required?: true, empty?: false},
            %Element{name: :purpose, type: :binary, required?: false, empty?: false},
            %Element{name: [:more_data], type: :list, required?: true, empty?: false}
          ]
        }
      ]
    }
  ]

  @test_map_reference_malformed_children [
    %Element{name: "id", type: :binary, required?: true, empty?: false},
    %Element{name: "dateTime", type: :binary, required?: true, empty?: true},
    %Element{name: "information", type: :binary, required?: true, empty?: true},
    %Element{name: :number, type: :binary, required?: true, empty?: false},
    %Element{name: {:number, :two}, type: :integer, required?: true},
    %Element{name: "optional_info", type: :binary, required?: false, empty?: true},
    %Element{name: "nestedMap", type: :map, required?: true,
      children:
        %Element{name: "nest", type: :map, required?: true,
          children: [
            %Element{name: "data", type: :list, required?: true, empty?: false},
            %Element{name: :purpose, type: :binary, required?: false, empty?: false},
            %Element{name: [:more_data], type: :list, required?: true, empty?: false}
          ]
        }

    }
  ]

  @test_map_2 %{
    "id" => "a211e016-845e-42be-b7ac-23111f441f7f",
    "dateTime" => "",
    "information" => "This is some stringy information",
    :number => "one",
    {:number, :two} => 2,
    "optional_info" => 567,
    "specialNestedMap" =>
    %{
      "nest" =>
      %{
        "data" => [1,2,3,4,5,6,7,8,9,10],
        :purpose => "To live",
        [:more_data] => [-1,-2,-3,-4,-5]
      }
    }
  }

  @test_map_3 %{
    "specialMap" =>
    %{
      "arbitraryListOfChildren" =>
      [
        %{
          "data" => [1,2,3,4,5,6,7,8,9,10],
          :purpose => "To live",
          [:more_data] => [-1,-2,-3,-4,-5]
        },
        %{
          "data" => [11,12,13,14,15],
          :purpose => "Who knows",
          [:more_data] => [0,0,0]
        },
        %{
          "data" => [8,3,2],
          :purpose => "To live",
          [:more_data] => [-1,-2,-3,-4,-5]
        },
        %{
          "data" => [0,0,0],
          :purpose => "purpose?",
          [:more_data] => [9,3,2]
        }
      ]
    }
  }

  @test_map_3_reference [
    %Element{name: "specialMap", type: :map, required?: true,
      children: [
        %Element{name: "arbitraryListOfChildren", type: :list, required?: true,
          children: {
            %Element{name: "data", type: :list, required?: true},
            %Element{name: :purpose, type: :binary, required?: true},
            %Element{name: [:more_data], type: :list, required?: true}
          }
        }
      ]
    }
  ]

  @test_map_4 %{
    "map" =>
      %{
        "nestedMap" =>
          %{
            "arbitraryListOfChildren" =>
              [
                %{
                  "data" => [1,2,3,4,5,6,7,8,9,10],
                  :purpose => "To live",
                  [:more_data] => [-1,-2,-3,-4,-5]
                },
                %{
                  "data" => [1,2,3,4,5,6,7,8,9,10],
                  :purpose => "To live",
                  [:more_data] => [-1,-2,-3,-4,-5]
                },
                %{
                  "data" => [1,2,3,4,5,6,7,8,9,10],
                  :purpose => "To live",
                  [:more_data] => [-1,-2,-3,-4,-5]
                }
              ]
          }
      }
  }

  @test_map_4_reference [
    %Element{name: "map", type: :map, required?: true, children:
      [
        %Element{name: "nestedMap", type: :map, required?: true, children:
          [
            %Element{name: "arbitraryListOfChildren", type: :list, required?: true, children:
              {
                %Element{name: "data", type: :list, required?: true},
                %Element{name: :purpose, type: :binary, required?: true},
                %Element{name: [:more_data], type: :list, required?: true}
              }
            }
          ]
        }
      ]
    },
  ]


  describe "validator" do
    test "validate/2 with valid data retruns a valid DeepMap" do
      deep_map =
        %DeepMap{data: @test_map, reference: @test_map_reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{"element1" => ""}
      reference = [%Element{name: "element1", type: :binary, required?: true, empty?: true}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{:element1 => ""}
      reference = [%Element{name: :element1, type: :binary, required?: true, empty?: true}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{1 => ""}
      reference = [%Element{name: 1, type: :binary, required?: true, empty?: true}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{1 => "one"}
      reference = [%Element{name: 1, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{[1, 2] => "one two"}
      reference = [%Element{name: [1, 2], type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{{[1, 2]} => "one two"}
      reference = [%Element{name: {[1, 2]}, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      data = %{{1, 2} => "one two"}
      reference = [%Element{name: {1, 2}, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []


      deep_map =
        %DeepMap{data: @test_map_3, reference: @test_map_3_reference}
        |> Hornet.validate()
      assert deep_map.valid? == true
      assert deep_map.errors == []
    end

    test "validate/2 with invalid data retruns an invalid DeepMap" do
      data = %{:key1 => %{:key2 => %{:key3 => "value"}}}
      reference = [%Element{name: :key1, type: :map, required?: true, children: [
        %Element{name: :key2, type: :map, required?: true, children: [
          %Element{name: :key3, type: :integer, required?: true}
        ]}
      ]}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert  [{:key3, "is invalid", [parent: _parent], [type: :integer, validation: :cast]}] = deep_map.errors
      assert [database_column: {":key3 is invalid, parent: " <> _parent , [type: :integer, validation: :cast]}] = Hornet.get_ecto_errors(deep_map, :database_column)


      data = %{"element1" => ""}
      reference = [%Element{name: "element1", type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
        assert deep_map.valid? == false
        assert deep_map.errors == [{"element1", "can't be blank", [parent: %{}], [type: :binary, validation: :cast]}]


      data = %{{1, 2} => ""}
      reference = [%Element{name: {1, 2}, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert deep_map.errors == [{{1,2}, "can't be blank", [parent: %{}], [type: :binary, validation: :cast]}]
      assert [database_column: {"{1, 2} can't be blank, parent: " <> _parent, [type: :binary, validation: :cast]}] = Hornet.get_ecto_errors(deep_map, :database_column)


      data = %{[1, 2] => ""}
      reference = [%Element{name: [1, 2], type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert deep_map.errors == [{[1,2], "can't be blank", [parent: %{}], [type: :binary, validation: :cast]}]
      assert [database_column: {"[1, 2] can't be blank, parent: " <> _parent, [type: :binary, validation: :cast]}] = Hornet.get_ecto_errors(deep_map, :database_column)


      data = %{:atom_key => ""}
      reference = [%Element{name: :atom_key, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert deep_map.errors == [{:atom_key, "can't be blank", [parent: %{}], [type: :binary, validation: :cast]}]
      assert [database_column: {":atom_key can't be blank, parent: " <> _parent, [type: :binary, validation: :cast]}] = Hornet.get_ecto_errors(deep_map, :database_column)


      data = %{%{key: :value} => ""}
      reference = [%Element{name: %{key: :value}, type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: data, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert deep_map.errors == [{%{key: :value}, "can't be blank", [parent: %{}], [type: :binary, validation: :cast]}]
      assert [database_column: {"%{key: :value} can't be blank, parent: " <> _parent, [type: :binary, validation: :cast]}] = Hornet.get_ecto_errors(deep_map, :database_column)


      deep_map =
        %DeepMap{data: @test_map_2, reference: @test_map_reference}
        |> Hornet.validate()
      assert deep_map.valid? == false


      deep_map =
        %DeepMap{data: @test_map_malformed, reference: @test_map_reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert 2 == length(deep_map.errors) # "information" and "data" are invalid in the malformed map


      deep_map =
        %DeepMap{data: @test_map, reference: @test_map_reference_malformed_children}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert [{"nestedMap", "reference children is invalid", [parent: _parent], [type: "children", validation: :cast]}] = deep_map.errors
    end

    test "validate/2 with malformed reference or data returns an error" do
      reference = %Element{name: "id", type: :binary, required?: true, empty?: false} # not an array
      deep_map =
        %DeepMap{data: %{"id" => "237483bhd8"}, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert [{"map", "is invalid", [parent: %{}], [type: :map, validation: :cast]}] == deep_map.errors

      deep_map =
        %DeepMap{data: [%{"id" => "237483bhd8"}], reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert [{"map", "is invalid", [parent: %{}], [type: :map, validation: :cast]}] == deep_map.errors

      reference = [%Element{name: "id", type: :binary, required?: true, empty?: false}]
      deep_map =
        %DeepMap{data: {"id","237483bhd8"}, reference: reference}
        |> Hornet.validate()
      assert deep_map.valid? == false
      assert [{"map", "is invalid", [parent: %{}], [type: :map, validation: :cast]}] == deep_map.errors
    end

    test "validate_type/4 with correct type returns valid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true, empty?: false}]
      deep_map = %DeepMap{data: %{"id" => "237483bhd8"}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :binary, %{}) == deep_map

      reference = [%Element{name: "id", type: :number, required?: true}]
      deep_map = %DeepMap{data: %{"id" => 237483.32}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :number, %{}) == deep_map
      deep_map = %DeepMap{data: %{"id" => 2374}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :number, %{}) == deep_map

      reference = [%Element{name: "id", type: :integer, required?: true}]
      deep_map = %DeepMap{data: %{"id" => 23748332}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :integer, %{}) == deep_map

      reference = [%Element{name: "id", type: :float, required?: true}]
      deep_map = %DeepMap{data: %{"id" => 23748332.32}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :float, %{}) == deep_map

      reference = [%Element{name: "id", type: :atom, required?: true}]
      deep_map = %DeepMap{data: %{"id" => :id}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :atom, %{}) == deep_map

      reference = [%Element{name: "id", type: :boolean, required?: true}]
      deep_map = %DeepMap{data: %{"id" => false}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :boolean, %{}) == deep_map

      reference = [%Element{name: "id", type: :boolean, required?: true}]
      deep_map = %DeepMap{data: %{"id" => :true}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :boolean, %{}) == deep_map

      reference = [%Element{name: "id", type: :list, required?: true}]
      deep_map = %DeepMap{data: %{"id" => [1,2,3,4]}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :list, %{}) == deep_map

      reference = [%Element{name: "id", type: :map, required?: true}]
      deep_map = %DeepMap{data: %{"id" => %{"id" => "id"}}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :map, %{}) == deep_map

      reference = [%Element{name: "id", type: :tuple, required?: true}]
      deep_map = %DeepMap{data: %{"id" => {"id", "id"}}, reference: reference}
      assert Hornet.__validate_type__(deep_map, "id", :tuple, %{}) == deep_map
    end

    test "validate_type/4 with incorrect type returns invalid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true, empty?: false}]
      deep_map = %DeepMap{data: %{"id" => :f237483bhd8}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :binary, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :number, required?: true}]
      deep_map = %DeepMap{data: %{"id" => "237483.32"}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :number, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :integer, required?: true}]
      deep_map = %DeepMap{data: %{"id" => 23748332.4}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :integer, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :float, required?: true}]
      deep_map = %DeepMap{data: %{"id" => 23748332}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :float, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :atom, required?: true}]
      deep_map = %DeepMap{data: %{"id" => ":id"}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :atom, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :boolean, required?: true}]
      deep_map = %DeepMap{data: %{"id" => "false"}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :boolean, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :list, required?: true}]
      deep_map = %DeepMap{data: %{"id" => {1,2,3,4}}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :list, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :map, required?: true}]
      deep_map = %DeepMap{data: %{"id" => {"id", "id"}}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :map, %{})
      assert validated != deep_map
      assert validated.valid? == false

      reference = [%Element{name: "id", type: :tuple, required?: true}]
      deep_map = %DeepMap{data: %{"id" => %{"id" => "id"}}, reference: reference}
      validated = Hornet.__validate_type__(deep_map, "id", :tuple, %{})
      assert validated != deep_map
      assert validated.valid? == false
    end

    test "__validate_has_key__/5 with correct data returns valid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true}]
      deep_map =
        %DeepMap{data: %{"id" => "43kj2l"}, reference: reference}
      assert Hornet.__validate_has_key__(deep_map, Enum.at(reference, 0), "id", :binary, %{}) == deep_map
    end

    test "__validate_has_key__/5 with incorrect data returns invalid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true}]
      deep_map = %DeepMap{data: %{}, reference: reference}
      validated = Hornet.__validate_has_key__(deep_map, Enum.at(reference, 0), "id", :binary, %{})
      assert validated != deep_map
      assert validated.valid? == false
    end

    test "__validate_not_empty__/5 with correct data returns valid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true, empty?: false}]
      deep_map = %DeepMap{data: %{"id" => "43kj2l"}, reference: reference}
      assert Hornet.__validate_not_empty__(deep_map, Enum.at(reference, 0), "id", :binary, %{}) == deep_map

      reference = [%Element{name: "id", type: :binary, required?: true, empty?: true}]
      deep_map = %DeepMap{data: %{"id" => "43kj2l"}, reference: reference}
      assert Hornet.__validate_not_empty__(deep_map, Enum.at(reference, 0), "id", :binary, %{}) == deep_map

      reference = [%Element{name: "id", type: :binary, required?: true, empty?: true}]
      deep_map = %DeepMap{data: %{"id" => ""}, reference: reference}
      assert Hornet.__validate_not_empty__(deep_map, Enum.at(reference, 0), "id", :binary, %{}) == deep_map
    end

    test "__validate_not_empty__/5 with incorrect data returns invalid validator" do
      reference = [%Element{name: "id", type: :binary, required?: true, empty?: false}]
      deep_map = %DeepMap{data: %{"id" => ""}, reference: reference}
      validated = Hornet.__validate_not_empty__(deep_map, Enum.at(reference, 0), "id", :binary, %{})
      assert validated != deep_map
      assert validated.valid? == false
    end
  end
end
