defmodule Vimond.Client.ProductTest do
  use ExUnit.Case, async: true
  import Vimond.Client
  import Mox

  setup :verify_on_exit!

  @config %Vimond.Config{base_url: "https://vimond-rest-api.example.com/api/platform/"}

  test "with product that has description" do
    HTTPClientMock
    |> expect(
      :get,
      fn "https://vimond-rest-api.example.com/api/platform/productgroup/1083/products/1400",
         Accept: "application/json; v=3; charset=UTF-8",
         "Content-Type": "application/json; v=3; charset=UTF-8" ->
        %HTTPotion.Response{
          status_code: 200,
          body: Jason.encode!(%{description: "C More Premium"}),
          headers: %HTTPotion.Headers{
            hdrs: %{"content-type" => "application/json;v=\"3\";charset=UTF-8"}
          }
        }
      end
    )

    assert product(1083, 1400, @config) == {:ok, %{description: "C More Premium"}}
  end

  test "with product that doesn't have description" do
    HTTPClientMock
    |> expect(
      :get,
      fn "https://vimond-rest-api.example.com/api/platform/productgroup/1083/products/1400",
         Accept: "application/json; v=3; charset=UTF-8",
         "Content-Type": "application/json; v=3; charset=UTF-8" ->
        %HTTPotion.Response{
          status_code: 200,
          body: Jason.encode!(%{}),
          headers: %HTTPotion.Headers{
            hdrs: %{"content-type" => "application/json;v=\"3\";charset=UTF-8"}
          }
        }
      end
    )

    assert product(1083, 1400, @config) == {:ok, %{description: nil}}
  end
end
