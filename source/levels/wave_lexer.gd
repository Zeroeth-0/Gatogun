# source/levels/wave_lexer.gd
# Converts a wave file string into a flat list of typed tokens
class_name WaveLexer
extends RefCounted

# ==============================================================================
# TOKEN
# ==============================================================================

enum TokenType {
	SPAWN,    ## EnemyName@N3:R>S|0.5  or  EnemyName at N3 ...
	WAIT,     ## WAIT
	MARKER,   ## [MARKER_NAME]
	PATTERN,  ## SWARM(...) EnemyName@...
	COMMENT,  ## ; anything
	EMPTY,
	ERROR,
}

class Token:
	var type:      TokenType
	var raw:       String
	var line:      int
	var error_msg: String

	func _init(t: TokenType, r: String, ln: int) -> void:
		type = t
		raw  = r
		line = ln

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Tokenizes the full source string
static func tokenize(source: String) -> Array[Token]:
	var tokens: Array[Token] = []
	var lines   := source.split("\n")
	var has_err := false
	
	for i in lines.size():
		var raw := lines[i].strip_edges()
		var ln  := i + 1
		var t   := _classify(raw, ln)
		if t.type == TokenType.ERROR:
			push_error("WaveLexer [line %d]: %s" % [ln, t.error_msg])
			has_err = true
		tokens.append(t)
	
	if has_err: push_warning("WaveLexer: file contains errors. Execution may be incomplete.")
	return tokens

# ==============================================================================
# INTERNAL
# ==============================================================================

static func _classify(raw: String, ln: int) -> Token:
	if raw.is_empty(): return Token.new(TokenType.EMPTY, raw, ln)
	
	if raw.begins_with(";"): return Token.new(TokenType.COMMENT, raw, ln)
	
	var upper := raw.to_upper()
	
	if upper == "WAIT": return Token.new(TokenType.WAIT, raw, ln)
	
	if raw.begins_with("[") and raw.ends_with("]"): return Token.new(TokenType.MARKER, raw, ln)
	
	if _is_pattern(upper): return Token.new(TokenType.PATTERN, raw, ln)
	
	# Normalize keywords to symbol form before checking for @
	var normalized := _normalize(raw)
	if "@" in normalized and not normalized.begins_with("@"): return Token.new(TokenType.SPAWN, raw, ln)
	
	var t      := Token.new(TokenType.ERROR, raw, ln)
	t.error_msg = "Unrecognized line: '%s'" % raw
	return t

static func _is_pattern(upper: String) -> bool:
	for name in ["SWARM", "LADDER", "PARADE", "MIRROR"]:
		if upper.begins_with(name): return true
	return false

static func _normalize(line: String) -> String:
	return line\
		.replace(" at ", "@")\
		.replace(" with ", ":")\
		.replace(" to ", ">")\
		.replace(" after ", "|")
