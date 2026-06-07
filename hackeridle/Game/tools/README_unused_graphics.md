# Unused Graphics Report

`graphics_usage_report.gd` is a Godot 4 editor tool backend that scans `res://Game` and writes:

```text
res://Game/tools/unused_graphics_report.csv
```

Manual run:

1. Open `res://Game/tools/find_unused_graphics.gd`.
2. In the script editor, use **File > Run**.
3. Read the summary in the Godot output panel.
4. Open `res://Game/tools/unused_graphics_report.csv`.

Editor menu setup:

1. Create `res://addons/graphics_usage_report/plugin.cfg`.
2. Use this content:

```ini
[plugin]

name="Graphics Usage Report"
description="Adds a Project > Tools action that scans graphic assets and writes unused_graphics_report.csv."
author="HackerIDLE"
version="1.0.0"
script="res://Game/tools/graphics_usage_editor_plugin.gd"
```

3. In Godot, enable **Project > Project Settings > Plugins > Graphics Usage Report**.
4. Run the report from **Project > Tools > Generate Graphics Usage Report**.

Report statuses:

- `USED_DIRECT`: the asset path appears directly in a scene, resource, script, theme, material, config, or data file.
- `MAYBE_USED_DYNAMIC`: no direct reference was found, but a script uses `load()`, `preload()`, or `ResourceLoader` with a path that may cover this asset.
- `UNUSED_CANDIDATE`: no direct reference and no dynamic hint were found.

Do not delete `UNUSED_CANDIDATE` files blindly. Move them to a temporary quarantine folder first, then run the game and exports before deleting them.
