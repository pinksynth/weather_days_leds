defmodule HTTPTestClient do
  # Mock for IP
  def get("https://api.ipify.org" <> _),
    do: {:ok, %HTTPoison.Response{body: "1.1.1.1", status_code: 200}}

  # Mock for coords from IP
  def get("http://api.ipstack.com" <> _),
    do:
      {:ok,
       %HTTPoison.Response{
         body: Jason.encode!(%{"longitude" => "100", "latitude" => "100"}),
         status_code: 200
       }}

  # Mock for weather from coords
  def get("https://api.openweathermap.org" <> _),
    do:
      {:ok,
       %HTTPoison.Response{
         body: Jason.encode!([%{"key" => "val"}]),
         status_code: 200
       }}
end
