defmodule Vimond.Client.AuthenticateTest do
  use ExUnit.Case, async: true
  alias Vimond.Config
  import Vimond.Client
  import Mox

  setup :verify_on_exit!

  @config %Config{
    base_url: "https://vimond-rest-api.example.com/api/platform/"
  }

  test "with valid credentials" do
    HTTPClientMock
    |> expect(:post, fn "https://vimond-rest-api.example.com/api/authentication/user/login",
                        body,
                        Accept: "application/json; v=3; charset=UTF-8",
                        "Content-Type": "application/json; v=2; charset=UTF-8" ->
      assert Jason.decode!(body) == %{
               "username" => "valid_user",
               "password" => "password",
               "rememberMe" => true
             }

      %HTTPotion.Response{
        status_code: 200,
        body:
          Jason.encode!(%{
            "code" => "AUTHENTICATION_OK",
            "description" => "Authentication successful",
            "reference" => "ba5e8d5105be5ce7",
            "status" => 200,
            "userId" => 6_572_908
          }),
        headers: %HTTPotion.Headers{
          hdrs: %{
            "content-type" => "application/json; v=3;charset=UTF-8",
            "authorization" => "Bearer valid_vimond_authorization_token",
            "set-cookie" => [
              "rememberMe=deleteMe; Path=/api; Max-Age=0; Expires=Mon, 13-Feb-2017 13:29:05 GMT",
              "rememberMe=VIMOND_REMEMBER_ME; Path=/api; Max-Age=31536000; Expires=Wed, 14-Feb-2018 13:29:05 GMT; HttpOnly"
            ]
          }
        }
      }
    end)

    assert authenticate("valid_user", "password", @config) ==
             {:ok,
              %{
                session: %Vimond.Session{
                  expires: 1_518_614_945,
                  vimond_authorization_token: "valid_vimond_authorization_token",
                  vimond_remember_me: "VIMOND_REMEMBER_ME"
                },
                user: %Vimond.User{
                  user_id: "6572908"
                }
              }}
  end

  test "with invalid credentials" do
    HTTPClientMock
    |> expect(:post, fn _url, _body, _headers ->
      %HTTPotion.Response{
        status_code: 401,
        body:
          Jason.encode!(%{
            "code" => "AUTHENTICATION_FAILED",
            "description" => "Incorrect username or password",
            "reference" => "157e55a3a8e3b97e",
            "status" => 401
          }),
        headers: %HTTPotion.Headers{
          hdrs: %{"content-type" => "application/json; v=3;charset=UTF-8"}
        }
      }
    end)

    assert authenticate("valid_user", "wrong_password", @config) ==
             {:error,
              %{
                source_errors: ["Incorrect username or password"],
                type: :invalid_credentials
              }}
  end

  test "handles errors" do
    HTTPClientMock
    |> expect(:post, fn _url, _body, _headers ->
      %HTTPotion.Response{
        status_code: 200,
        body: Jason.encode!(%{"unexpected" => "value"}),
        headers: %HTTPotion.Headers{
          hdrs: %{"content-type" => "application/json; v=3;charset=UTF-8"}
        }
      }
    end)

    assert authenticate("error_user", "error_password", @config) ==
             {:error, %{type: :generic, source_errors: ["Unexpected error"]}}
  end
end
