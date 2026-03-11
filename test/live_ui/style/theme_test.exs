defmodule LiveUi.Style.ThemeTest do
  use ExUnit.Case, async: true

  alias LiveUi.Style.Theme

  test "exposes default tokens for the core design categories" do
    tokens = Theme.default_tokens()

    assert get_in(tokens, ["spacing", "md"]) == "1rem"
    assert get_in(tokens, ["typography", "family"]) =~ "IBM Plex Sans"
    assert get_in(tokens, ["color", "accent"]) == "#0f766e"
    assert get_in(tokens, ["elevation", "modal"]) =~ "rgba"
    assert get_in(tokens, ["motion", "normal"]) == "180ms"
  end

  test "merges host overrides into css variables without changing the token schema" do
    vars =
      Theme.css_variables(%{
        color: %{accent: "#224488"},
        typography: %{heading_family: "Fraunces, serif"}
      })

    assert vars["--live-ui-color-accent"] == "#224488"
    assert vars["--live-ui-typography-heading-family"] == "Fraunces, serif"
    assert vars["--live-ui-color-surface"] == "#ffffff"
  end
end
