defmodule LiveUi.IUR.DependencyTest do
  use ExUnit.Case, async: true

  alias LiveUi.IUR.Dependency

  test "accepts complete canonical schema markers" do
    assert :ok =
             Dependency.validate_markers(%{
               "schema" => "unified_iur",
               "source" => "unified-ui",
               "version" => "1.0.0",
               "kind" => "button"
             })

    assert Dependency.markers_present?(%{"schema" => "unified_iur"})
  end

  test "rejects incomplete marker sets" do
    assert {:error, error} =
             Dependency.validate_markers(%{"schema" => "unified_iur", "kind" => "button"})

    assert error.message =~ "incomplete"
  end

  test "rejects unsupported schema names" do
    assert {:error, error} =
             Dependency.validate_markers(%{
               "schema" => "other_schema",
               "source" => "unified-ui",
               "version" => "1.0.0"
             })

    assert error.message =~ "unsupported"
  end
end
