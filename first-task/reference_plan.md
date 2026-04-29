Root cause:
`BaseModel.model_construct()` resolves `AliasPath` values by looking into the remaining `values` mapping, but unlike plain aliases it never marks the top-level alias-path source as consumed. When `extra='allow'`, the leftover `values` mapping is assigned to `__pydantic_extra__`, so the nested source dictionary is incorrectly retained as an extra field and appears in dumps.

Intended fix:
Track the root keys of alias paths that successfully populate fields during `model_construct()`. Do not mutate the input mapping immediately, because multiple fields can read from the same root. When extra fields are collected, exclude only those consumed alias-path roots while leaving unrelated extra keys intact.

Test plan:
Add a regression test for a model with `extra='allow'` and two fields populated from the same `AliasPath` root. It should construct both fields and keep only an unrelated extra key. Add a passing control test showing plain alias extra handling remains unchanged.
