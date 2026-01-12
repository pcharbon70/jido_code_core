defmodule JidoCodeCore.KnowledgeGraph.Entity do
  @moduledoc """
  Represents a code entity in the knowledge graph.

  An entity can be a module, function, type, protocol, behaviour, or other
  Elixir code construct. Entities are stored in the RDF graph and connected
  through semantic relationships.

  ## Fields

  - `type` - The entity type (`:module`, `:function`, `:type`, etc.)
  - `name` - The entity name as an atom or string
  - `module` - The containing module (nil for top-level modules)
  - `arity` - Function/macro arity (nil for non-callable entities)
  - `visibility` - `:public` or `:private`
  - `file_path` - Source file path
  - `line_number` - Line number in source file
  - `doc` - Documentation string
  - `metadata` - Additional metadata map

  ## Examples

      # A module entity
      %JidoCodeCore.KnowledgeGraph.Entity{
        type: :module,
        name: MyApp.User,
        file_path: "lib/my_app/user.ex",
        line_number: 1,
        doc: "User management module"
      }

      # A function entity
      %JidoCodeCore.KnowledgeGraph.Entity{
        type: :function,
        name: :create,
        module: MyApp.User,
        arity: 1,
        visibility: :public,
        file_path: "lib/my_app/user.ex",
        line_number: 15
      }
  """

  @type entity_type ::
          :module
          | :function
          | :type
          | :protocol
          | :behaviour
          | :macro
          | :struct
          | :exception

  @type visibility :: :public | :private

  @type t :: %__MODULE__{
          type: entity_type(),
          name: atom() | String.t(),
          module: module() | nil,
          arity: non_neg_integer() | nil,
          visibility: visibility() | nil,
          file_path: String.t() | nil,
          line_number: pos_integer() | nil,
          doc: String.t() | nil,
          metadata: map()
        }

  defstruct [
    :type,
    :name,
    :module,
    :arity,
    :visibility,
    :file_path,
    :line_number,
    :doc,
    metadata: %{}
  ]

  @doc """
  Creates a new entity with the given type and name.

  ## Examples

      iex> JidoCodeCore.KnowledgeGraph.Entity.new(:module, MyApp.User)
      %JidoCodeCore.KnowledgeGraph.Entity{type: :module, name: MyApp.User, metadata: %{}}

      iex> JidoCodeCore.KnowledgeGraph.Entity.new(:function, :create, module: MyApp.User, arity: 1)
      %JidoCodeCore.KnowledgeGraph.Entity{type: :function, name: :create, module: MyApp.User, arity: 1, metadata: %{}}
  """
  @spec new(entity_type(), atom() | String.t(), keyword()) :: t()
  def new(type, name, opts \\ []) do
    struct(__MODULE__, [{:type, type}, {:name, name} | opts])
  end

  @doc """
  Returns the fully qualified name of the entity.

  For functions, this includes the module and arity.
  For modules, this is just the module name.

  ## Examples

      iex> entity = JidoCodeCore.KnowledgeGraph.Entity.new(:function, :create, module: MyApp.User, arity: 1)
      iex> JidoCodeCore.KnowledgeGraph.Entity.qualified_name(entity)
      "MyApp.User.create/1"

      iex> entity = JidoCodeCore.KnowledgeGraph.Entity.new(:module, MyApp.User)
      iex> JidoCodeCore.KnowledgeGraph.Entity.qualified_name(entity)
      "MyApp.User"
  """
  @spec qualified_name(t()) :: String.t()
  def qualified_name(%__MODULE__{type: :module, name: name}) do
    to_string(name)
  end

  def qualified_name(%__MODULE__{type: type, name: name, module: module, arity: arity})
      when type in [:function, :macro] do
    base = if module, do: "#{module}.#{name}", else: to_string(name)
    if arity, do: "#{base}/#{arity}", else: base
  end

  def qualified_name(%__MODULE__{name: name, module: module}) do
    if module, do: "#{module}.#{name}", else: to_string(name)
  end

  @doc """
  Generates an RDF IRI for this entity.

  The IRI is based on the entity's qualified name, URL-encoded for safety.

  ## Examples

      iex> entity = JidoCodeCore.KnowledgeGraph.Entity.new(:module, MyApp.User)
      iex> JidoCodeCore.KnowledgeGraph.Entity.to_iri(entity)
      ~I<https://jidocode.dev/entity/MyApp.User>
  """
  @spec to_iri(t()) :: RDF.IRI.t()
  def to_iri(%__MODULE__{} = entity) do
    base = entity_base_iri()
    name = qualified_name(entity) |> URI.encode()
    RDF.iri("#{base}#{name}")
  end

  @doc """
  Returns the base IRI for JidoCodeCore entities.
  """
  @spec entity_base_iri() :: String.t()
  def entity_base_iri, do: "https://jidocode.dev/entity/"
end
