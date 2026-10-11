# Historical Isar schema fixture

`project_model.dart` and `project_model.g.dart` are unchanged copies of the
released `Project` model and its generated schema at commit
`abdeab4007d0b519feba90731b2914bc31387756` (v1.4.39).

The backup upgrade test creates a real Isar database with this historical schema
before opening it with the current schema. This verifies that adding local
project notes and the default-false `isLocalArchive` field preserves project
identity, stage names, photos, trips and original-currency amounts. Do not
regenerate this fixture when generating current application schemas.
