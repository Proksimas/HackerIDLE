@tool
extends RefCounted

const SCAN_ROOT := "res://Game"
const OUTPUT_CSV := "res://Game/tools/unused_graphics_report.csv"

const GRAPHIC_EXTENSIONS := [
	"png",
	"jpg",
	"jpeg",
	"webp",
	"svg",
	"bmp",
	"tga",
	"exr",
	"hdr",
]

const TEXT_EXTENSIONS := [
	"gd",
	"tscn",
	"tres",
	"theme",
	"material",
	"cfg",
	"json",
	"csv",
	"txt",
	"shader",
]

const LOAD_MARKERS := [
	"load(",
	"preload(",
	"ResourceLoader.load",
	"ResourceLoader.exists",
]


func generate() -> Dictionary:
	var all_files := _collect_files(SCAN_ROOT)
	var graphic_files := _filter_by_extensions(all_files, GRAPHIC_EXTENSIONS)
	var text_files := _filter_by_extensions(all_files, TEXT_EXTENSIONS)
	var text_cache := _read_text_files(text_files)
	var direct_references := _find_direct_references(graphic_files, text_cache)
	var dynamic_hints := _find_dynamic_load_hints(text_cache)
	var rows := _build_report_rows(graphic_files, direct_references, dynamic_hints)
	var summary := _build_summary(rows)

	_write_csv(rows)
	_print_summary(summary)
	return summary


func _collect_files(root_path: String) -> Array[String]:
	var result: Array[String] = []
	_collect_files_recursive(root_path, result)
	result.sort()
	return result


func _collect_files_recursive(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			_collect_files_recursive(full_path, result)
		else:
			result.append(full_path)

		file_name = dir.get_next()
	dir.list_dir_end()


func _filter_by_extensions(paths: Array[String], extensions: Array) -> Array[String]:
	var result: Array[String] = []
	for path in paths:
		if path == OUTPUT_CSV:
			continue

		if _has_extension(path, extensions):
			result.append(path)
	return result


func _has_extension(path: String, extensions: Array) -> bool:
	var extension := path.get_extension().to_lower()
	return extensions.has(extension)


func _read_text_files(paths: Array[String]) -> Dictionary:
	var result := {}
	for path in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("Cannot read file: %s" % path)
			continue

		result[path] = file.get_as_text()
		file.close()
	return result


func _find_direct_references(assets: Array[String], text_cache: Dictionary) -> Dictionary:
	var references := {}
	for asset_path in assets:
		references[asset_path] = []

	for text_path in text_cache.keys():
		var content: String = text_cache[text_path]
		for asset_path in assets:
			if text_path == asset_path:
				continue

			if _content_references_asset(content, asset_path):
				references[asset_path].append(text_path)

	return references


func _content_references_asset(content: String, asset_path: String) -> bool:
	if content.find(asset_path) != -1:
		return true

	var without_res := asset_path.trim_prefix("res://")
	if content.find(without_res) != -1:
		return true

	var quoted_relative := asset_path.trim_prefix("res://Game/")
	if content.find(quoted_relative) != -1:
		return true

	return false


func _find_dynamic_load_hints(text_cache: Dictionary) -> Dictionary:
	var hints := {}
	for text_path in text_cache.keys():
		if text_path.get_extension().to_lower() != "gd":
			continue

		var content: String = text_cache[text_path]
		if not _contains_any(content, LOAD_MARKERS):
			continue

		var detected_paths := _extract_res_paths_from_script(content)
		if detected_paths.is_empty() and content.find("Graphics") != -1:
			detected_paths.append("res://Game/Graphics")

		for detected_path in detected_paths:
			if not hints.has(detected_path):
				hints[detected_path] = []
			hints[detected_path].append(text_path)

	return hints


func _contains_any(content: String, markers: Array) -> bool:
	for marker in markers:
		if content.find(marker) != -1:
			return true
	return false


func _extract_res_paths_from_script(content: String) -> Array[String]:
	var paths: Array[String] = []
	var regex := RegEx.new()
	var err := regex.compile("""["'](res://[^"']+)["']""")
	if err != OK:
		push_warning("Cannot compile dynamic path regex.")
		return paths

	for match_result in regex.search_all(content):
		var detected_path := match_result.get_string(1)
		if not detected_path.begins_with(SCAN_ROOT):
			continue

		if _has_extension(detected_path, GRAPHIC_EXTENSIONS):
			paths.append(detected_path.get_base_dir())
		elif not paths.has(detected_path):
			paths.append(detected_path)

	return paths


func _build_report_rows(
	assets: Array[String],
	direct_references: Dictionary,
	dynamic_hints: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for asset_path in assets:
		var references: Array = direct_references.get(asset_path, [])
		var matching_hints := _matching_dynamic_hints(asset_path, dynamic_hints)
		var status := "UNUSED_CANDIDATE"

		if not references.is_empty():
			status = "USED_DIRECT"
		elif not matching_hints.is_empty():
			status = "MAYBE_USED_DYNAMIC"

		rows.append({
			"status": status,
			"asset_path": asset_path,
			"size_bytes": _file_size(asset_path),
			"referenced_by": references,
			"dynamic_hint_sources": matching_hints,
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["status"] == b["status"]:
			return a["asset_path"] < b["asset_path"]
		return a["status"] < b["status"]
	)
	return rows


func _matching_dynamic_hints(asset_path: String, dynamic_hints: Dictionary) -> Array[String]:
	var matches: Array[String] = []
	for hinted_path in dynamic_hints.keys():
		if asset_path == hinted_path or asset_path.begins_with(hinted_path.trim_suffix("/") + "/"):
			for source in dynamic_hints[hinted_path]:
				if not matches.has(source):
					matches.append(source)
	return matches


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0

	var size := file.get_length()
	file.close()
	return size


func _write_csv(rows: Array[Dictionary]) -> void:
	var file := FileAccess.open(OUTPUT_CSV, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report: %s" % OUTPUT_CSV)
		return

	file.store_line("status,asset_path,size_bytes,referenced_by,dynamic_hint_sources")
	for row in rows:
		file.store_csv_line([
			row["status"],
			row["asset_path"],
			str(row["size_bytes"]),
			_join_paths(row["referenced_by"]),
			_join_paths(row["dynamic_hint_sources"]),
		])

	file.close()
	print("Unused graphics report written to: %s" % OUTPUT_CSV)


func _build_summary(rows: Array[Dictionary]) -> Dictionary:
	var summary := {
		"assets_scanned": rows.size(),
		"used_direct": 0,
		"maybe_used_dynamic": 0,
		"unused_candidates": 0,
		"unused_candidate_size": 0,
		"report_path": OUTPUT_CSV,
	}

	for row in rows:
		match row["status"]:
			"USED_DIRECT":
				summary["used_direct"] += 1
			"MAYBE_USED_DYNAMIC":
				summary["maybe_used_dynamic"] += 1
			"UNUSED_CANDIDATE":
				summary["unused_candidates"] += 1
				summary["unused_candidate_size"] += row["size_bytes"]

	return summary


func _print_summary(summary: Dictionary) -> void:
	print("--- Graphics usage report ---")
	print("Assets scanned: %d" % summary["assets_scanned"])
	print("Used directly: %d" % summary["used_direct"])
	print("Maybe used dynamically: %d" % summary["maybe_used_dynamic"])
	print("Unused candidates: %d" % summary["unused_candidates"])
	print("Unused candidate size: %.2f MB" % (float(summary["unused_candidate_size"]) / 1024.0 / 1024.0))
	print("Report: %s" % summary["report_path"])


func _join_paths(paths: Array) -> String:
	var parts: PackedStringArray = []
	for path in paths:
		parts.append(str(path))
	return ";".join(parts)
