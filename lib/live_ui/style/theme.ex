defmodule LiveUi.Style.Theme do
  @moduledoc """
  Library-owned theme contract for `live_ui` widgets and IUR-driven rendering.
  """

  use Phoenix.Component

  @root_class "live-ui-theme"
  @data_attr "default"

  @default_tokens %{
    "color" => %{
      "accent" => "#0f766e",
      "accent-text" => "#f0fdfa",
      "border" => "#d1d5db",
      "danger" => "#b91c1c",
      "muted" => "#6b7280",
      "overlay" => "rgba(15, 23, 42, 0.48)",
      "surface" => "#ffffff",
      "surface-alt" => "#f7f8fb",
      "text" => "#111827"
    },
    "elevation" => %{
      "floating" => "0 12px 32px rgba(15, 23, 42, 0.18)",
      "modal" => "0 20px 48px rgba(15, 23, 42, 0.22)",
      "raised" => "0 4px 12px rgba(15, 23, 42, 0.12)"
    },
    "motion" => %{
      "fast" => "120ms",
      "normal" => "180ms",
      "slow" => "280ms"
    },
    "spacing" => %{
      "lg" => "1.5rem",
      "md" => "1rem",
      "sm" => "0.5rem",
      "xl" => "2rem",
      "xs" => "0.25rem"
    },
    "typography" => %{
      "body-size" => "1rem",
      "family" => "\"IBM Plex Sans\", \"Avenir Next\", \"Segoe UI\", sans-serif",
      "heading-family" => "\"Space Grotesk\", \"Avenir Next\", sans-serif",
      "heading-weight" => "600",
      "mono-family" => "\"IBM Plex Mono\", \"SFMono-Regular\", monospace",
      "small-size" => "0.875rem"
    }
  }

  @spec default_tokens() :: map()
  def default_tokens, do: @default_tokens

  @spec merge_tokens(map()) :: map()
  def merge_tokens(overrides) when is_map(overrides) do
    deep_merge(@default_tokens, normalize_map(overrides))
  end

  def merge_tokens(_overrides), do: @default_tokens

  @spec css_variables(map()) :: map()
  def css_variables(overrides \\ %{}) do
    overrides
    |> merge_tokens()
    |> flatten_tokens()
    |> Enum.into(%{}, fn {path, value} -> {css_var_name(path), normalize_css_value(value)} end)
  end

  @spec inline_variables(map()) :: String.t() | nil
  def inline_variables(overrides \\ %{}) do
    overrides
    |> css_variables()
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join("; ", fn {key, value} -> "#{key}: #{value}" end)
    |> case do
      "" -> nil
      css -> css
    end
  end

  @spec container_attrs(map(), keyword()) :: keyword()
  def container_attrs(overrides \\ %{}, opts \\ []) do
    extra_class = Keyword.get(opts, :class)
    extra_style = Keyword.get(opts, :style)

    [
      {"class", join_classes([@root_class, extra_class])},
      {"data-live-ui-theme", @data_attr},
      {"style", join_styles([extra_style, inline_variables(overrides)])}
    ]
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
  end

  attr(:id, :string, default: nil)
  attr(:tokens, :map, default: %{})
  attr(:class, :any, default: nil)
  attr(:style, :string, default: nil)
  slot(:inner_block, required: true)

  def scope(assigns) do
    assigns =
      assigns
      |> assign(
        :theme_attrs,
        container_attrs(assigns.tokens, class: assigns.class, style: assigns.style)
      )

    ~H"""
    <section id={@id} {@theme_attrs}>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp normalize_map(map) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} ->
      key = normalize_key(key)

      normalized_value =
        if is_map(value) do
          normalize_map(value)
        else
          value
        end

      {key, normalized_value}
    end)
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      if is_map(left_value) and is_map(right_value) do
        deep_merge(left_value, right_value)
      else
        right_value
      end
    end)
  end

  defp flatten_tokens(tokens), do: flatten_tokens(tokens, [])

  defp flatten_tokens(tokens, path) do
    Enum.flat_map(tokens, fn {key, value} ->
      if is_map(value) do
        flatten_tokens(value, path ++ [key])
      else
        [{path ++ [key], value}]
      end
    end)
  end

  defp css_var_name(path), do: "--live-ui-" <> Enum.map_join(path, "-", &normalize_key/1)

  defp normalize_key(key) when is_atom(key), do: key |> Atom.to_string() |> normalize_key()

  defp normalize_key(key) when is_binary(key) do
    key
    |> String.trim()
    |> String.downcase()
    |> String.replace("_", "-")
    |> String.replace(~r/[^a-z0-9_\-]+/u, "-")
  end

  defp normalize_key(key), do: key |> to_string() |> normalize_key()

  defp normalize_css_value(value) when is_binary(value), do: value
  defp normalize_css_value(value) when is_integer(value), do: Integer.to_string(value)

  defp normalize_css_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 2)

  defp normalize_css_value(value), do: to_string(value)

  defp join_classes(classes) do
    classes
    |> List.wrap()
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end

  defp join_styles(styles) do
    styles
    |> List.wrap()
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("; ")
  end
end
