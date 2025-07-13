%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      strict: true,
      color: true,
      checks: [
        # Disabled checks
        {Credo.Check.Consistency.ExceptionNames, false},
        {Credo.Check.Consistency.LineEndings, false},
        {Credo.Check.Consistency.ParameterPatternMatching, false},
        {Credo.Check.Consistency.SpaceAroundOperators, false},
        {Credo.Check.Consistency.SpaceInParentheses, false},
        {Credo.Check.Consistency.TabsOrSpaces, false},

        # For some checks, like AliasUsage, you can only customize the priority
        # Priority values are: `low, normal, high, higher`
        {Credo.Check.Design.AliasUsage, priority: :low, if_called_more_often_than: 2},

        # For others you can set parameters
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},

        # You can also customize the exit_status of each check.
        # If you don't want TODO comments to cause `mix credo` to fail, just
        # set this value to 0 (zero).
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0},

        # To deactivate a check:
        # Put `false` as second element:
        {Credo.Check.Design.DocComment, false},

        # ... or put `false` as third element:
        {Credo.Check.Design.DocComment, []},

        # You can also change the base_priority of a check
        # (higher base_priority = lower actual priority)
        {Credo.Check.Readability.Specs, base_priority: :high}

        # Custom checks can be created using `mix credo.gen.check`.
        #
      ]
    }
  ]
}
