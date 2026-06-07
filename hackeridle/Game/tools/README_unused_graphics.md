# Unused Graphics Report

`graphics_usage_report.gd` is a Godot 4 editor tool backend that scans `res://Game` and writes:

```text
res://Game/tools/unused_graphics_report.csv
```

Install as a Godot editor tool:

1. Open `res://Game/tools/install_graphics_usage_tool.gd`.
2. In the script editor, use **File > Run**.
3. If the menu item is not visible immediately, reload the project.
4. Run the report from **Project > Tools > Generate Graphics Usage Report**.

Manual run without installing the menu item:

1. Open `res://Game/tools/find_unused_graphics.gd`.
2. In the script editor, use **File > Run**.
3. Read the summary in the Godot output panel.
4. Open `res://Game/tools/unused_graphics_report.csv`.

Report statuses:

- `USED_DIRECT`: the asset path appears directly in a scene, resource, script, theme, material, config, or data file.
- `MAYBE_USED_DYNAMIC`: no direct reference was found, but a script uses `load()`, `preload()`, or `ResourceLoader` with a path that may cover this asset.
- `UNUSED_CANDIDATE`: no direct reference and no dynamic hint were found.

The CSV uses `;` as the column separator. The `size_mb` column is written in megabytes, rounded to 3 decimals. Multiple paths inside `referenced_by` and `dynamic_hint_sources` are separated with `|`.

Do not delete `UNUSED_CANDIDATE` files blindly. Move them to a temporary quarantine folder first, then run the game and exports before deleting them.
