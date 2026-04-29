<uploaded_files>
/app/pydantic-assessment
</uploaded_files>
I've uploaded a code repository in the directory `/app/pydantic-assessment`. Consider the following task:

`BaseModel.model_construct()` mishandles nested validation aliases when the model allows extras.

A field can be populated from a path-based alias, for example `AliasPath('envelope', 'sku')`. After that lookup succeeds, the outer key that made the lookup possible has already been used as input for model fields. In trusted construction mode, that outer key should not also be recorded as an extra attribute.

Update construction so successful alias-path reads reserve their top-level source key for field population. Models with `extra='allow'` should still retain unrelated entries, such as an audit identifier supplied beside the nested data, and ordinary aliases should continue to behave as they do today. Be careful not to remove a path root unless a field was actually populated from that path, since a missing nested value should leave the original input available as extra data.
