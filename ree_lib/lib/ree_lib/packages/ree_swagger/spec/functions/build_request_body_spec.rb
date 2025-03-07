RSpec.describe :build_request_body_schema_spec do
  link :build_request_body_schema, from: :ree_swagger
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :cast, output: :symbol_key_hash),
    ]

    build_mapper_factory(
      strategies: strategies
    )
  }

  it {
    caster = mapper_factory.call.use(:cast) do
      string :name
      string :email
      string? :last_name
    end

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        email: { type: "string" },
        last_name: { type: "string" }
      },
      required: ["name", "email"]
    }

    expect(build_request_body_schema(caster)).to eq(schema)
  }
end
