%{
  configs: [
    %{
      name: "default",
      color: true,
      files: %{
        included: ["config/", "lib/", "test/", "*.exs"],
        excluded: ["lib/envoy/", "lib/google/"]
      },
      checks: [
        # Don't fail on TODOs and FIXMEs for now
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0},

        # mix format seems to enforce a line length of 100
        {Credo.Check.Readability.MaxLineLength, max_length: 100},
      ]
    }
  ]
}
