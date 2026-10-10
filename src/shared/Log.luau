--!strict
-- Central logging. All game code logs through this module instead of raw
-- print/warn, so format and level are consistent and debugging is easier.
-- Pure pieces (formatting, sink) are testable under Lune.

export type Level = "debug" | "info" | "warn" | "error"
export type Sink = (level: Level, text: string) -> ()
export type Context = { [string]: any }

export type Logger = {
	debug: (message: string, context: Context?) -> (),
	info: (message: string, context: Context?) -> (),
	warn: (message: string, context: Context?) -> (),
	error: (message: string, context: Context?) -> (),
}

local PREFIX = "[BeDino]"

local Log = {}

local debugEnabled = false

local function defaultSink(level: Level, text: string)
	if level == "info" or level == "debug" then
		print(text)
	else
		warn(text)
	end
end

local sink: Sink = defaultSink

local function formatContext(context: Context?): string
	if context == nil then
		return ""
	end
	local keys = {}
	for key in context do
		table.insert(keys, key)
	end
	table.sort(keys)
	local parts = {}
	for _, key in keys do
		table.insert(parts, string.format("%s=%s", key, tostring(context[key])))
	end
	if #parts == 0 then
		return ""
	end
	return " " .. table.concat(parts, " ")
end

-- Replaces the output target (used by tests) and returns the previous one.
function Log.setSink(newSink: Sink): Sink
	local previous = sink
	sink = newSink
	return previous
end

function Log.setDebugEnabled(enabled: boolean)
	debugEnabled = enabled
end

function Log.new(tag: string): Logger
	local function emit(level: Level, message: string, context: Context?)
		if level == "debug" and not debugEnabled then
			return
		end
		sink(level, string.format("%s[%s] %s%s", PREFIX, tag, message, formatContext(context)))
	end

	return {
		debug = function(message, context)
			emit("debug", message, context)
		end,
		info = function(message, context)
			emit("info", message, context)
		end,
		warn = function(message, context)
			emit("warn", message, context)
		end,
		error = function(message, context)
			emit("error", message, context)
		end,
	}
end

return Log
