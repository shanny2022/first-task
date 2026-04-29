<uploaded_files>
/app/pydantic-assessment
</uploaded_files>
I've uploaded a code repository in the directory `/app/pydantic-assessment`. Consider the following task:

`BaseModel.model_construct()` does not handle `AliasPath` inputs consistently when extra fields are allowed.

When a field is populated from a nested validation alias such as `AliasPath('payload', 'value')`, the top-level container that supplied the field should be treated as consumed input, just like a plain alias is. A model configured with `extra='allow'` should still keep unrelated extra keys, but it should not preserve the alias-path root itself in `model_extra` or include it in `model_dump()`.

For example, constructing a model with two fields read from `payload.first` and `payload.second` plus an unrelated `trace_id` extra should set both fields and keep only `trace_id` as extra. The original `payload` dictionary should not appear as an extra value.

Make `model_construct()` match that behavior while preserving existing handling for plain aliases, multiple fields that read from the same alias-path root, and unrelated extra fields.
