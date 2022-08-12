# TODOs

- [ ] More specs on "" empty strings
- [ ] More specs on evironment-specific contracts with/without "default" section
- [ ] Allow callable validators to return non-boolean values for processing them as non-callable validators.
- [ ] README: Describe how to validate interdependency of ENV vars.
- [ ] Cover all named validators with specs.
- [ ] README: Describe alternative gems, pros and cons
- [ ] Implement a tool that tracks ENV var reading and matches to contract coverage.
- [ ] Implement :crontab validator
- [ ] Allow ranges as validators:

    ```ruby
    contract = {
      XYZ_HOUR: 1..12,
      XYZ_TIMEOUT_SEC: 0..3600,
    }
    ```
