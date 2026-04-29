#!/bin/bash
set -euo pipefail

cd "/app/pydantic-assessment"

cat > /tmp/solution.patch <<'__SOLUTION__'
diff --git a/pydantic/main.py b/pydantic/main.py
index 2ed62e5f3e..6a43c88d6 100644
--- a/pydantic/main.py
+++ b/pydantic/main.py
@@ -339,6 +339,7 @@ class BaseModel(metaclass=_model_construction.ModelMetaclass):
         m = cls.__new__(cls)
         fields_values: dict[str, Any] = {}
         fields_set = set()
+        used_alias_path_roots: list[Any] = []
 
         for name, field in cls.__pydantic_fields__.items():
             if field.alias is not None and field.alias in values:
@@ -362,6 +363,8 @@ class BaseModel(metaclass=_model_construction.ModelMetaclass):
                         if value is not PydanticUndefined:
                             fields_values[name] = value
                             fields_set.add(name)
+                            if alias.path:
+                                used_alias_path_roots.append(alias.path[0])
                             break
 
             if name not in fields_set:
@@ -373,7 +376,13 @@ class BaseModel(metaclass=_model_construction.ModelMetaclass):
         if _fields_set is None:
             _fields_set = fields_set
 
-        _extra: dict[str, Any] | None = values if cls.model_config.get('extra') == 'allow' else None
+        if cls.model_config.get('extra') == 'allow':
+            if used_alias_path_roots:
+                _extra: dict[str, Any] | None = {
+                    key: value for key, value in values.items() if key not in used_alias_path_roots
+                }
+            else:
+                _extra = values
+        else:
+            _extra = None
         _object_setattr(m, '__dict__', fields_values)
         _object_setattr(m, '__pydantic_fields_set__', _fields_set)
         if not cls.__pydantic_root_model__:
__SOLUTION__

git apply --verbose /tmp/solution.patch
