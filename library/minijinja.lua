-- SPDX-License-Identifier: MIT

---@meta

--- A filter callback.
---
--- It takes a `State` as the first paramter followed by any number of args.
---
--- Returns any value.
---
---@alias Filter fun(state: State, ...): any

--- A test callback
---
--- It takes a `State` as the first parameter followed by any number of args.
---
--- Must return a boolean
---
---@alias Test fun(state, ...): boolean

--- Determines how undefined variables are handled.
---
---@alias UndefinedBehavior
---| "chainable"
---| "lenient"
---| "semi-strict"
---| "strict"

--- Determines how autoescaping is applied
---
---@alias AutoEscape
---| "html"
---| "json"
---| "none"

--- Configure the syntax for the environment
---
---@class (exact) SyntaxConfig
---
---@field block_delimiters? [string, string]
---@field variable_delimiters? [string, string]
---@field comment_delimiters? [string, string]
---@field line_statement_prefix? string
---@field line_comment_prefix? string

--- A minijinja environment
---
---@class (exact) Environment: userdata
---
---@field keep_trailing_newline boolean
---@field trim_blocks boolean
---@field lstrip_blocks boolean
---@field debug boolean
---@field fuel number
---@field recursion_limit number
---@field undefined_behavior UndefinedBehavior
Environment = {}

--- Create a new environment
---
---@return Environment
function Environment:new() end

--- Add a template
---
---@param name string
---@param source string
function Environment:add_template(name, source) end

--- Remove a template
---
---@param name string
function Environment:remove_template(name) end

--- Remove all templates
function Environment:clear_templates() end

--- Return a table of all undeclared template variables
---
---@param nested boolean
---
---@return table
function Environment:undeclared_variables(nested) end

--- Register a template loader as source of templates
---
---@param loader fun(name: string): string|nil
function Environment:set_loader(loader) end

--- Sets a callback to join template paths
---
---@param callback fun(name: string, parent: string): string
function Environment:set_path_join_callback(callback) end

--- Sets a callback invoked for unknown methods on objects.
---
---@param callback fun(state: State, value: any, method: string)
function Environment:set_unknown_method_callback(callback) end

--- Sets a new function to select the default auto escaping.
---
---@param callback fun(name: string): AutoEscape
function Environment:set_auto_escape_callback(callback) end

--- Sets a different formatter function.
---
---@param formatter fun(state: State, value: any)
function Environment:set_formatter(formatter) end

--- Sets the syntax for the environment.
---
---@param syntax SyntaxConfig
function Environment:set_syntax(syntax) end

--- Render a template
---
---@param name string
---@param ctx table
---
---@return string
function Environment:render_template(name, ctx) end

--- Render a string
---
---@param source string
---@param ctx table
---@param name? string
---
---@return string
function Environment:render_str(source, ctx, name) end

--- Evaluate an expression
---
---@param source string
---@param ctx table
---
---@return any
function Environment:eval(source, ctx) end

--- Add a filter
---
---@param name string
---@param filter Filter
---@param pass_state? boolean pass a State as the first arg
function Environment:add_filter(name, filter, pass_state) end

--- Remove a filter
---
---@param name string
function Environment:remove_filter(name) end

--- Add a test
---
---@param name string
---@param test Test
---@param pass_state? boolean pass a State as the first arg
function Environment:add_test(name, test, pass_state) end

--- Remove a test
---
---@param name string
function Environment:remove_test(name) end

--- Add a global value
---
---@param name string
---@param global any
---@param pass_state? boolean pass a State as the first arg
function Environment:add_global(name, global, pass_state) end

--- Remove a global value
---
---@param name string
function Environment:remove_global(name) end

--- Get a list of all global variables
---
---@return any[]
function Environment:globals() end

--- A minijinja state.
---
--- Only accesible within filters, tests, and global functions.
---
---@class (exact) State: userdata
State = {}

--- Returns the name of the current template.
---
---@return string
function State:name() end

--- Returns the current value of the auto escape flag.
---
---@return AutoEscape
function State:auto_escape() end

--- Returns the current undefined behavior.
---
---@return UndefinedBehavior
function State:undefined_behavior() end

--- Returns the name of the innermost block.
---
---@return string
function State:current_block() end

--- Looks up a variable by name in the context.
---
---@param name string
---
---@return any
function State:lookup(name) end

--- Looks up a global macro and calls it.
---
---@param name string
---@param ... any
---
---@return string
function State:call_macro(name, ...) end

--- Returns a list of the names of all exports (top-level variables).
---
---@return string[]
function State:exports() end

--- Returns a list of all known variables.
---
---@return string[]
function State:known_variables() end

--- Invokes a filter with some arguments.
---
---@param filter string
---@param ... any
---
---@return any
function State:apply_filter(filter, ...) end

--- Invokes a test function on a value.
---
---@param test string
---@param ... any
---
---@return boolean
function State:perform_test(test, ...) end

--- Formats a value to a string using the formatter on the environment.
---
---@param value any
---
---@return string
function State:format(value) end

--- Returns the fuel levels.
---
---@return [number, number]
function State:fuel_levels() end

--- Looks up a temp and returns it.
---
---@param name string
---
---@return any
function State:get_temp(name) end

--- Inserts a temp and returns the old temp.
---
---@param name string
---@param temp any
---
---@return any
function State:set_temp(name, temp) end

--- Get a temp or call func to add the value
---
---@param name string
---@param func fun(): any
---
---@return any
function State:get_or_set_temp(name, func) end
