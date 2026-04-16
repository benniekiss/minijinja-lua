--[[
a pandoc filter utilizing minijinja.
]]

local minijinja = require("minijinja")

---@class (exact) JinjaSettings
---
---@field reload_before_render? boolean
---@field keep_trailing_newline? boolean
---@field trim_blocks? boolean
---@field lstrip_blocks? boolean
---@field debug? boolean
---@field fuel? integer
---@field recursion_limit? integer
---@field undefined_behavior? minijinja.UndefinedBehavior
---@field context? table
local JinjaSettings = {
    reload_before_render = nil,
    keep_trailing_newline = nil,
    trim_blocks = nil,
    lstrip_blocks = nil,
    debug = nil,
    fuel = nil,
    recursion_limit = nil,
    undefined_behavior = nil,
    context = nil,
}

local JSON_EXTS = pandoc.List({ ".json" })

local YAML_EXTS = pandoc.List({ ".yaml", ".yml" })

--- Check if an extension is a JSON extension
---
---@param ext string
---
---@return boolean
local function has_json_ext(ext)
    return JSON_EXTS:includes(ext)
end

--- Check if an extension is a YAML extension
---
---@param ext string
---
---@return boolean
local function has_yaml_ext(ext)
    return YAML_EXTS:includes(ext)
end

--- Read a file and return the contents, or nil if the file could not be read.
---
---@param path string
---
---@return string|nil
local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        pandoc.log.error("failed to read file: " .. path)
        return
    end

    local content = file:read("a")
    file:close()

    return content
end

--- Load a JSON file
---
---@param path string
---
---@return table|nil
local function load_json(path)
    local json = read_file(path)
    if json == nil then return end

    local ctx = pandoc.json.decode(json, false)

    if pandoc.utils.type(ctx) ~= "table" then
        pandoc.error("invalid json: ", pandoc.utils.stringify(ctx))
        return
    end

    return ctx
end

--- Load a YAML file
---
---@param path string
---
---@return table|nil
local function load_yaml(path)
    local yaml = read_file(path)
    if yaml == nil then return end

    local ctx = pandoc.read(yaml, "markdown").meta

    if pandoc.utils.type(ctx) ~= "table" then
        pandoc.error("invalid yaml: ", pandoc.utils.stringify(ctx))
        return
    end

    return ctx
end

--- Load a context from a JSON or YAML file
---
---@param path string
---
---@return string|nil
local function load_context_from_file(path)
    if not pandoc.path.exists(context) then
        pandoc.log.error("file does not exist: " .. context)
        return
    end

    local _, ext = pandoc.path.split_extension(path)
    local is_json = has_json_ext(ext)
    local is_yaml = has_yaml_ext(ext)

    if not (is_json or is_yaml) then
        pandoc.log.error("only JSON and YAML files are supported: " .. context)
    end

    if is_json then
        return load_json(path)
    end

    if is_yaml then
        return load_yaml(path)
    end
end

--- Load a minijinja context
---
---@param context string|table
local function load_context(context)
    local is_string = pandoc.utils.type(context) == "string"
    local is_table = pandoc.utils.type(context) == "table"

    if not (is_string or is_table) then
        pandoc.log.error("`context` must be a filepath or a table: " .. context)
        return
    end

    if is_table then
        JinjaSettings.context = context
    end

    if is_string then
        JinjaSettings.context = load_context_from_file(context)
    end
end

local function Meta(meta)
    local mj = meta.minijinja

    if mj == nil then return end

    local context = mj.context
    if context ~= nil then
        load_context(context)
    end

    JinjaSettings.reload_before_render = mj.reload_before_render
    JinjaSettings.keep_trailing_newline = mj.keep_trailing_newline
    JinjaSettings.trim_blocks = mj.trim_blocks
    JinjaSettings.lstrip_blocks = mj.lstrip_blocks
    JinjaSettings.debug = mj.debug
    JinjaSettings.fuel = mj.fuel
    JinjaSettings.recursion_limit = mj.recursion_limit
    JinjaSettings.undefined_behavior = mj.undefined_behavior
end

local function Pandoc(doc)
    doc = doc:walk({ Meta = Meta })

    local env = minijinja.Environment:new()

    env.reload_before_render = JinjaSettings.reload_before_render
    env.keep_trailing_newline = JinjaSettings.keep_trailing_newline
    env.trim_blocks = JinjaSettings.trim_blocks
    env.lstrip_blocks = JinjaSettings.lstrip_blocks
    env.debug = JinjaSettings.debug
    env.fuel = JinjaSettings.fuel
    env.recursion_limit = JinjaSettings.recursion_limit
    env.undefined_behavior = JinjaSettings.undefined_behavior

    local source = pandoc.write(doc, "markdown")
    local rendered = env:render_str(source, JinjaSettings.context, PANDOC_STATE.output_file)

    return pandoc.read(rendered, "markdown")
end

return {
    Meta = Meta,
    Pandoc = Pandoc,
}
