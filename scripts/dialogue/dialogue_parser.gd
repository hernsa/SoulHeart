class_name DialogueParser

static func parse_text(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.contains(":"):
			var parts := line.split(":", true, 1)
			out.append({"speaker": parts[0].strip_edges(), "text": parts[1].strip_edges()})
		else:
			out.append({"speaker": "", "text": line})
	return out

static func parse_file(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: %s" % path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var content := f.get_as_text()
	f.close()
	return parse_text(content)
