// SPDX-License-Identifier: MIT

mod contrib;
mod convert;
mod environment;
mod state;

use mlua::prelude::{Lua, LuaFunction, LuaResult, LuaTable, LuaValue};

pub use crate::environment::LuaEnvironment;

#[cfg_attr(feature = "module", mlua::lua_module(name = "minijinja"))]
pub fn minijinja_lua(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;

    table.set(
        "type",
        lua.create_function(|_, val: LuaValue| contrib::minijinja_types(&val))?,
    )?;

    let path_loader = contrib::minijinja_path_loader(lua)?;
    table.set(
        "path_loader",
        lua.create_function(move |_, val: LuaValue| -> Result<LuaFunction, _> {
            path_loader.call(val)
        })?,
    )?;

    table.set("None", LuaValue::NULL)?;
    table.set("Environment", lua.create_proxy::<LuaEnvironment>()?)?;

    Ok(table)
}
