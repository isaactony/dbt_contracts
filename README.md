# Data contract demo: catching a breaking schema change before it merges

A minimal, real, runnable dbt project demonstrating the scenario from the
article outline: a producer team renames a column, and instead of that
break surfacing three days later in a downstream team's dashboard, it
fails the pull request itself.

