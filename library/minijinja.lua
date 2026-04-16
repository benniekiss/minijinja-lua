-- SPDX-License-Identifier: MIT

---@meta

--- Minijinja types
---
---@alias Types
---| "environment"
---| "state"
---| "none"

--- Determines how undefined values are handled.
---
--- Can be provided to [`Environment.undefined_behavior`](lua://Environment.undefined_behavior).
---
---@alias UndefinedBehavior
--- printing: empty string
--- iteration: empty array
--- attributes: fails
--- test: falsey
---| "lenient"
--- printing: empty string
--- iteration: empty array
--- attributes: undefined
--- test: falsey
---| "chainable"
--- printing: fails
--- iteration: fails
--- attributes: fails
--- test: falsey
---| "semi-strict"
--- printing: fails
--- iteration: fails
--- attributes: fails
--- test: fails
---| "strict"

--- Determines how autoescaping is applied.
---
---@alias AutoEscape
---| "html"
---| "json"
---| "none"

--- A minijinja callback.
---
--- It takes a [`State`](lua://State) as the first paramter followed by any number of args.
---
---@alias Callback fun(state: State, ...): any

--- A stateless minijinja callback.
---
--- Similar to a [`Filter`](lua://Filter), but it is not passed a [`State`](lua://State).
---
---@alias CallbackStateless fun(...): any

--- A minijinja global variable.
---
--- This type can be provided to [`Environment:add_global`](lua://Environment.add_global)
---
---@alias Global any|Callback|CallbackStateless

--- A minijinja filter function.
---
--- This type of function can be provided to [`Environment:add_filter`](lua://Environment.add_filter)
---
---@alias Filter Callback|CallbackStateless

--- A minijinja test function.
---
--- This type of function can be provided to [`Environment:add_test`](lua://Environment.add_test)
---
---@alias Test Callback|CallbackStateless

--- A template loader callback.
---
--- It takes the name of a template and returns the source or `nil` if no template could be found.
---
--- This type of function can be provided to [`Environment:set_loader`](lua://Environment.set_loader) to load templates from a filesystem.
---
---@alias LoaderCallback fun(name: string): string|nil

--- A path join callback
---
--- It takes the name of a template and the parent path and returns a new derived path.
---
--- This type of function can be provided to [`Environment:set_path_join_callback`](lua://Environment.set_path_join_callback) to implement relative path resolution between templates.
---
---@alias PathJoinCallback fun(name: string, parent: string): string

--- A callback invoked for unknown methods on objects.
---
--- It takes a [`State`](lua://State), the object which the method was called on, the name of the method, and any arguments passed and returns any value.
---
--- This type of function can be provided to [`Environment:set_unknown_method_callback`](lua://Environment.set_unknown_method_callback) to implement compatibility with python methods.
---
---@alias UnknownMethodCallback fun(state: State, value: any, method: string, args: any[]): any

--- A callback to select the default auto escaping.
---
--- It takes the name of a template and returns an [`AutoEscape`](lua://AutoEscape) variant.
---
--- This type of function can be provided to [`Environment:set_auto_escape_callback`](lua://Environment.set_auto_escape_callback).
---
---@alias AutoEscapeCallback fun(name: string): AutoEscape

--- A callback to control how values are formatted.
---
--- It takes a [`State`](lua://State) and a value to be formatted, and it returns the formatted value as a string.
---
--- This type of function can be provided to [`Environment:set_formatter`](lua://Environment.set_formatter).
---
---@alias FormatterCallback fun(state: State, value: any): string

--- This value can be used in place of `nil` to indicate intentionally null values.
---
--- It maps to the `minijinja` `None` value.
---
---@alias None userdata

--- Configure the syntax for the environment.
---
---@class (exact) SyntaxConfig
---
---@field block_delimiters? [string, string] Start and end delimiters
---@field variable_delimiters? [string, string] Start and end delimiters
---@field comment_delimiters? [string, string] Start and end delimiters
---@field line_statement_prefix? string
---@field line_comment_prefix? string

--- A minijinja environment.
---
---@class (exact) Environment: userdata
---
---@field reload_before_render boolean Reload templates before each render.
---@field keep_trailing_newline boolean Preserve trailing newlines at the end of templates.
---@field trim_blocks boolean Remove the first newline after a block.
---@field lstrip_blocks boolean Remove leading spaces and tabs from the start of a line to a block.
---@field debug boolean Enable debug behavior.
---@field fuel number|nil Sets the fuel of the engine. If `nil`, fuel usage is disabled.
---@field recursion_limit number Reconfigures the runtime recursion limit. Default is 500.
---@field undefined_behavior UndefinedBehavior Changes the undefined behavior. Default is [`lenient`](lua://UndefinedBehavior.lenient).
Environment = {}

--- Create a new environment.
---
---@return Environment
function Environment:new() end

--- Create an empty environment.
---
--- This environment has no default filters, tests, or globals.
---
---@return Environment
function Environment:empty() end

--- Add a template.
---
---@param name string The name of the template.
---@param source string The template source contents.
function Environment:add_template(name, source) end

--- Remove a template.
---
---@param name string The name of the template.
function Environment:remove_template(name) end

--- Remove all templates.
function Environment:clear_templates() end

--- Return a table of all undeclared template variables.
---
---@param nested boolean If `true`, nested trivial attribute lookups are also returned.
---
---@return table
function Environment:undeclared_variables(nested) end

--- Sets a callback to load template sources.
---
---@param callback LoaderCallback
function Environment:set_loader(callback) end

--- Sets a callback to join template paths.
---
---@param callback PathJoinCallback
function Environment:set_path_join_callback(callback) end

--- Sets a callback invoked for unknown methods on objects.
---
---@param callback UnknownMethodCallback
function Environment:set_unknown_method_callback(callback) end

--- Sets a callback to select the default auto escaping behavior.
---
---@param callback AutoEscapeCallback
function Environment:set_auto_escape_callback(callback) end

--- Sets a callback to control how values are formatted.
---
---@param callback FormatterCallback
function Environment:set_formatter(callback) end

--- Sets the syntax for the environment.
---
---@param syntax SyntaxConfig
function Environment:set_syntax(syntax) end

--- Render a template.
---
---@param name string The name of the template to render.
---@param ctx? table The template context.
---
---@return string # The rendered template.
function Environment:render_template(name, ctx) end

--- Render a string directly.
---
---@param source string The template source.
---@param ctx? table The template context.
---@param name? string The name of the template. Defaults to `<string>`.
---
---@return string # The rendered template.
function Environment:render_str(source, ctx, name) end

--- Evaluate an expression.
---
---@param source string The expression source
---@param ctx? table The expression context.
---
---@return any # The result of the expression
function Environment:eval(source, ctx) end

--- Add a filter.
---
---@param name string The name of the filter.
---@param filter Filter The filter.
---@param pass_state? boolean Whether to pass a [`State`](lua://State) as the first argument.
function Environment:add_filter(name, filter, pass_state) end

--- Remove a filter.
---
---@param name string The name of the filter.
function Environment:remove_filter(name) end

--- Add a test.
---
---@param name string The name of the test.
---@param test Test The test.
---@param pass_state? boolean Whether to pass a [`State`](lua://State) as the first argument.
function Environment:add_test(name, test, pass_state) end

--- Remove a test.
---
---@param name string The name of the test.
function Environment:remove_test(name) end

--- Add a global variable.
---
---@param name string The name of the variable.
---@param global Global The variable.
---@param pass_state? boolean Whether to pass a [`State`](lua://State) as the first argument to function variables.
function Environment:add_global(name, global, pass_state) end

--- Remove a global variable.
---
---@param name string The name of the variable.
function Environment:remove_global(name) end

--- Get a list of all global variables.
---
---@return any[]
function Environment:globals() end

--- A minijinja state.
---
--- Only accesible within filters, tests, and global functions.
---
---@class (exact) State: userdata
State = {}

--- Get the name of the current template.
---
---@return string # The template name.
function State:name() end

--- Get the current value of the auto escape flag.
---
---@return AutoEscape # The current auto escape flag.
function State:auto_escape() end

--- Get the current undefined behavior.
---
---@return UndefinedBehavior # The current undefined behavior.
function State:undefined_behavior() end

--- Get the name of the innermost block.
---
---@return string # The name of the innermost block.
function State:current_block() end

--- Look up a variable in the render context by name.
---
---@param name string The name of the variable.
---
---@return any # The variable associated with `name`.
function State:lookup(name) end

--- Call a macro.
---
---@param name string The name of the macro.
---@param ... any Arguments to pass to the macro.
---
---@return string # The macro output.
function State:call_macro(name, ...) end

--- Get a list of names for all exports (top-level variables).
---
---@return string[]
function State:exports() end

--- Get a list of all known variables.
---
---@return string[]
function State:known_variables() end

--- Invokes a filter with some arguments.
---
---@param filter string The name of the filter.
---@param ... any Arguments to pass to the filter.
---
---@return any # The output of the filter.
function State:apply_filter(filter, ...) end

--- Invokes a test function on a value.
---
---@param test string The name of the test.
---@param ... any Arguments to pass to the test.
---
---@return boolean # The output of the test.
function State:perform_test(test, ...) end

--- Format a value to a string using the formatter configured for the environment.
---
---@param value any The value to format.
---
---@return string # The formatted value.
function State:format(value) end

--- Get the consumed and remaining fuel levels.
---
---@return [number, number] # The [consumed, remaining] fuel levels.
function State:fuel_levels() end

--- Look up a temp variable.
---
---@param name string The name of the variable.
---
---@return any # The variable associated with `name`.
function State:get_temp(name) end

--- Set a temp variable and return the old value.
---
---@param name string The name of the variable.
---@param temp any The temp variable.
---
---@return any # The old temp variable value.
function State:set_temp(name, temp) end

--- Get a temp variable or add the variable returned by `func`.
---
---@param name string The name of the variable.
---@param func fun(): any The function to call if the temp is not set.
---
---@return any # The variable associated with `name`, or the variable returnd by `func`.
function State:get_or_set_temp(name, func) end

--- Get the type of `value`
---
--- This function returns the strings
--- - `'environment'` for [`Environment`](lua://Environment)
--- - `'state'` for [`State`](lua://State)
--- - `'none'` for [`None`](lua://None)
--- - or the values returned by the builtin `type()` function.
---
---@param value any
---
---@return Types|string
function type(value) end

--- Get a callback to load templates from the provided directory paths.
---
--- The function returned by this one can be passed to [`Environment:set_loader`](lua://Environment.set_loader) to load templates from the filesystem.
---
---@param paths string|string[]
---
---@return LoaderCallback
function path_loader(paths) end
