defmodule JidoCodeCore.Utils.String do
  @moduledoc """
  String utility functions for JidoCodeCore.

  Provides helper functions for string manipulation and formatting.
  """

  @doc """
  Truncates a string to a maximum length, adding an ellipsis if truncated.

  ## Parameters

    - `string` - The string to truncate
    - `max_length` - Maximum length of the resulting string
    - `opts` - Optional keyword list

  ## Options

    - `:ellipsis` - String to append when truncated (default: "...")
    - `:break_word` - Whether to break words (default: false)

  ## Returns

  The truncated string.

  ## Examples

      iex> JidoCodeCore.Utils.String.truncate("Hello world", 8)
      "Hello..."

      iex> JidoCodeCore.Utils.String.truncate("Hello world", 8, ellipsis: "..")
      "Hello.."

      iex> JidoCodeCore.Utils.String.truncate("Hello world", 20)
      "Hello world"

  """
  @spec truncate(String.t(), pos_integer(), keyword()) :: String.t()
  def truncate(string, max_length, opts \\ [])

  def truncate(string, max_length, opts) when is_binary(string) and is_integer(max_length) do
    ellipsis = Keyword.get(opts, :ellipsis, "...")
    break_word = Keyword.get(opts, :break_word, false)

    if String.length(string) <= max_length do
      string
    else
      truncate(string, max_length, ellipsis, break_word)
    end
  end

  defp truncate(string, max_length, ellipsis, true = _break_word) do
    available_length = max_length - String.length(ellipsis)
    String.slice(string, 0, available_length) <> ellipsis
  end

  defp truncate(string, max_length, ellipsis, false = _break_word) do
    available_length = max_length - String.length(ellipsis)

    case find_last_space(string, available_length) do
      nil ->
        # No space found, break at max length
        String.slice(string, 0, available_length) <> ellipsis

      space_index ->
        # Truncate at last space
        String.slice(string, 0, space_index) <> ellipsis
    end
  end

  defp find_last_space(string, max_index) do
    string
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.filter(fn {char, _idx} -> char == " " end)
    |> Enum.filter(fn {_char, idx} -> idx <= max_index end)
    |> Enum.map(fn {_char, idx} -> idx end)
    |> Enum.max(fn -> nil end)
  end

  @doc """
  Converts a string to title case.

  ## Examples

      iex> JidoCodeCore.Utils.String.title_case("hello world")
      "Hello World"

      iex> JidoCodeCore.Utils.String.title_case("ELIXIR programming")
      "Elixir Programming"

  """
  @spec title_case(String.t()) :: String.t()
  def title_case(string) when is_binary(string) do
    string
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Removes all extra whitespace from a string, collapsing multiple spaces into one.

  ## Examples

      iex> JidoCodeCore.Utils.String.squish("hello    world")
      "hello world"

      iex> JidoCodeCore.Utils.String.squish("  hello   world  ")
      "hello world"

  """
  @spec squish(String.t()) :: String.t()
  def squish(string) when is_binary(string) do
    string
    |> String.split()
    |> Enum.join(" ")
  end

  @doc """
  Checks if a string is blank (empty or contains only whitespace).

  ## Examples

      iex> JidoCodeCore.Utils.String.blank?("")
      true

      iex> JidoCodeCore.Utils.String.blank?("   ")
      true

      iex> JidoCodeCore.Utils.String.blank?("hello")
      false

  """
  @spec blank?(String.t()) :: boolean()
  def blank?(string) when is_binary(string) do
    String.trim(string) == ""
  end

  @doc """
  Checks if a string is present (not empty and not just whitespace).

  ## Examples

      iex> JidoCodeCore.Utils.String.present?("hello")
      true

      iex> JidoCodeCore.Utils.String.present?("   ")
      false

      iex> JidoCodeCore.Utils.String.present?("")
      false

  """
  @spec present?(String.t()) :: boolean()
  def present?(string) when is_binary(string) do
    !blank?(string)
  end

  @doc """
  Converts a string to snake_case.

  ## Examples

      iex> JidoCodeCore.Utils.String.to_snake_case("HelloWorld")
      "hello_world"

      iex> JidoCodeCore.Utils.String.to_snake_case("helloWorld")
      "hello_world"

  """
  @spec to_snake_case(String.t()) :: String.t()
  def to_snake_case(string) when is_binary(string) do
    string
    |> String.replace(~r/[A-Z]/, "_\\0")
    |> String.downcase()
    |> String.replace_prefix("_", "")
    |> String.replace_suffix("_", "")
  end

  @doc """
  Converts a string to CamelCase.

  ## Examples

      iex> JidoCodeCore.Utils.String.to_camel_case("hello_world")
      "HelloWorld"

      iex> JidoCodeCore.Utils.String.to_camel_case("hello")
      "Hello"

  """
  @spec to_camel_case(String.t()) :: String.t()
  def to_camel_case(string) when is_binary(string) do
    string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end
end
