defmodule WeatherDaysNerves.Light do
  defstruct [:red, :green, :blue]
  alias Circuits.GPIO

  def turn_off(%__MODULE__{red: red, green: green, blue: blue} = light) do
    [red, green, blue]
    |> turn_off()

    light
  end

  def turn_off(pins) when is_list(pins) do
    Enum.each(pins, &turn_off/1)
  end

  def turn_off(pin) when is_integer(pin) do
    {:ok, pid} = GPIO.open(pin, :output)
    GPIO.write(pid, 0)
    :ok = GPIO.close(pid)
  end

  def turn_on(%__MODULE__{red: red, green: green, blue: blue} = light) do
    [red, green, blue]
    |> turn_on()

    light
  end

  def turn_on(pins) when is_list(pins) do
    Enum.each(pins, &turn_on/1)
  end

  def turn_on(pin) when is_integer(pin) do
    {:ok, pid} = GPIO.open(pin, :output)
    GPIO.write(pid, 1)
    :ok = GPIO.close(pid)
  end

  @primaries [:red, :green, :blue]
  @settable_colors [:white, :red, :yellow, :green, :cyan, :blue, :magenta, :off]
  @color_components [
    white: [:red, :green, :blue],
    red: [:red],
    yellow: [:red, :green],
    green: [:green],
    cyan: [:green, :blue],
    blue: [:blue],
    magenta: [:blue, :red],
    off: []
  ]
  def set_to_color(%__MODULE__{} = light, color)
      when color in @settable_colors do
    # Figure out what colors should be set
    pins_to_turn_on = @color_components[color] |> colors_to_pins(light)

    # Don't bother turning colors off if they must be set
    pins_to_turn_off =
      @primaries |> Enum.reject(&(&1 in pins_to_turn_on)) |> colors_to_pins(light)

    pins_to_turn_off
    |> turn_off()

    pins_to_turn_on
    |> turn_on()
  end

  def colors_to_pins(colors, %__MODULE__{} = light) when is_list(colors) do
    colors
    |> Enum.map(&Map.get(light, &1))
  end
end
