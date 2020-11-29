defmodule Boruta.Ecto.AdminTest do
  use Boruta.DataCase, async: true

  import Boruta.Factory

  alias Boruta.Ecto.Admin
  alias Boruta.Ecto.Client
  alias Boruta.Ecto.Scope

  @client_valid_attrs %{
    redirect_uri: ["https://redirect.uri"],
    access_token_ttl: 3600,
    authorization_code_ttl: 60
  }
  @client_update_attrs %{
    redirect_uri: ["https://updated.redirect.uri"],
    access_token_ttl: 3600,
    authorization_code_ttl: 60
  }

  # clients
  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(@client_valid_attrs)
      |> Admin.create_client()

    client
  end

  describe "list_clients/0" do
    test "returns all clients" do
      client = client_fixture()
      assert Admin.list_clients() == [client]
    end
  end

  describe "get_client/1" do
    test "returns the client with given id" do
      client = client_fixture()
      assert Admin.get_client!(client.id) == client
    end
  end

  describe "create_client/1" do
    test "returns error changeset with invalid redirect_uri (bad URI format)" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_client(%{
        redirect_uris: ["\\bad_redirect_uri"]
      })
    end

    test "creates a client" do
      assert {:ok, %Client{} } = Admin.create_client(@client_valid_attrs)
    end

    test "creates a client with a secret" do
      {:ok, %Client{secret: secret}} = Admin.create_client(@client_valid_attrs)
      assert secret
    end

    test "creates a client with authorized scopes" do
      scope = insert(:scope)
      assert {:ok,
        %Client{authorized_scopes: authorized_scopes}
      } = Admin.create_client(Map.put(@client_valid_attrs, :authorized_scopes, [%{"id" => scope.id}]))
      assert authorized_scopes == [scope]
    end
  end

  describe "update_client/2" do
    test "returns error changeset with invalid redirect_uri (bad URI format)" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_client(client, %{
        redirect_uris: ["$bad_redirect_uri"]
      })
      assert client == Admin.get_client!(client.id)
    end

    test "updates the client" do
      client = client_fixture()
      assert {:ok, %Client{} = client} = Admin.update_client(client, @client_update_attrs)
    end

    test "updates the client with authorized scopes" do
      scope = insert(:scope)
      client = client_fixture()
      assert {:ok,
        %Client{authorized_scopes: authorized_scopes}} = Admin.update_client(client, %{"authorized_scopes" => [%{"id" => scope.id}]})
      assert authorized_scopes == [scope]
    end
  end

  describe "delete_client/1" do
    test "deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = Admin.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_client!(client.id) end
    end
  end

  # scopes
  @scope_valid_attrs %{name: "some:name", public: true}
  @scope_update_attrs %{name: "some:updated:name", public: false}

  def scope_fixture(attrs \\ %{}) do
    {:ok, scope} =
      attrs
      |> Enum.into(%{name: SecureRandom.hex(64)})
      |> Admin.create_scope()

    scope
  end

  describe "list_scopes/0" do
    test "returns all scopes" do
      scope = scope_fixture()
      assert Admin.list_scopes() == [scope]
    end
  end

  describe "get_scope/1" do
    test "returns the scope with given id" do
      scope = scope_fixture()
      assert Admin.get_scope!(scope.id) == scope
    end
  end

  describe "get_scopes_by_ids/1" do
    test "returns the scopes with given id" do
      scopes = [scope_fixture(), scope_fixture()]
      ids = Enum.map(scopes, fn (%Scope{id: id}) -> id end)
      assert Admin.get_scopes_by_ids(ids) == scopes
    end
  end

  describe "create_scope/1" do
    test "returns error changeset with name missing" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_scope(%{name: nil})
      assert {:error, %Ecto.Changeset{}} = Admin.create_scope(%{name: ""})
    end

    test "returns error changeset with name containing whitespace" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_scope(%{name: "name with whitespace"})
    end

    test "creates a scope" do
      assert {:ok, %Scope{} = scope} = Admin.create_scope(@scope_valid_attrs)
      assert scope.name == "some:name"
      assert scope.public == true
    end

    test "creates a scope with public default to false" do
      assert {:ok, %Scope{} = scope} = Admin.create_scope(%{name: "name"})
      assert scope.public == false
    end
  end

  describe "update_scope/2" do
    setup do
      scope = scope_fixture()
      {:ok, scope: scope}
    end

    test "returns error changeset with name missing", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Admin.update_scope(scope, %{name: nil})
      assert {:error, %Ecto.Changeset{}} = Admin.update_scope(scope, %{name: ""})
      assert scope == Admin.get_scope!(scope.id)
    end

    test "returns error changeset with name containing whitespace", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Admin.update_scope(scope, %{name: "name with whitespace"})
    end

    test "returns error changeset with public set to nil", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} = Admin.update_scope(scope, %{public: nil})
      assert scope == Admin.get_scope!(scope.id)
    end

    test "updates the scope", %{scope: scope} do
      assert {:ok, %Scope{} = scope} = Admin.update_scope(scope, @scope_update_attrs)
      assert scope.name == "some:updated:name"
      assert scope.public == false
    end
  end

  describe "delete_scope/1" do
    setup do
      scope = scope_fixture()
      {:ok, scope: scope}
    end

    test "deletes the scope" do
      scope = scope_fixture()
      assert {:ok, %Scope{}} = Admin.delete_scope(scope)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_scope!(scope.id) end
    end
  end
end
