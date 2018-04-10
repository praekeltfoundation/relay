%{
  configs: [
    %{
      name: "default",
      color: true,
      files: %{
        # The default glob pattern matching doesn't match files starting with a '.'
        included:
          ["config/", "lib/", "test/", "*.exs"] ++ Path.wildcard(".*.exs", match_dot: true),
        excluded: []
      },
      checks: [
        # Don't fail on TODOs and FIXMEs for now
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0},

        # Sometimes Foo.Bar.thing is cleaner than an alias
        {Credo.Check.Design.AliasUsage, if_nested_deeper_than: 2},

        # mix format defaults to a line length of 98
        {Credo.Check.Readability.MaxLineLength, max_length: 98},

        # We use copy/pasted port numbers in tests a lot
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 65535},

        # Sometimes it makes sense to start a pipe chain with a function call
        {Credo.Check.Refactor.PipeChainStart,
         excluded_functions: ["Map.new", "Atom.to_string", "Keyword.get", "System.unique_integer"],
         excluded_argument_types: [:atom, :binary]}
      ]
    }
  ]
}
