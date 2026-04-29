Root cause:
During `model_construct()`, ordinary aliases are removed from the pending input once used, but `AliasPath` lookups only copy the nested value into the field. The mapping entry that held the nested data remains in `values`, so `extra='allow'` later stores it under `__pydantic_extra__`.

Intended fix:
While walking fields, remember the first component of each `AliasPath` that successfully finds a value. Delay filtering until extra data is assembled, because several fields can depend on the same outer object. When extras are allowed, build the extra mapping without those remembered roots; otherwise keep the existing ignore/forbid behavior.

Test plan:
Cover an allowed-extra model populated from nested alias paths, including multiple fields sharing one outer object and the case where no unrelated extras remain. Include controls for a failed alias-path lookup, a normal alias, and `extra='ignore'`.
