%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["config/", "lib/", "test/", "*.exs"],
        excluded: ["lib/envoy/", "lib/google/"]
      },
      checks: []
    }
  ]
}
