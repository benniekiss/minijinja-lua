use mlua::prelude::{Lua, LuaError, LuaFunction, LuaValue};

use crate::LuaEnvironment;

/// Helper to get the lua type for minijinja wrapper userdata.
///
/// Returns `environment`, `state`, `none`, or any other regular lua type name.
pub(crate) fn minijinja_types(val: &LuaValue) -> Result<&'static str, LuaError> {
    match val {
        LuaValue::UserData(ud) if ud.is::<LuaEnvironment>() => Ok("environment"),
        LuaValue::UserData(ud) if ud.type_name()? == Some("state".to_string()) => Ok("state"),
        val if val.is_null() => Ok("none"),
        _ => Ok(val.type_name()),
    }
}

/// Helper to load templates from a directory.
///
/// The returned function can be provided to `Environment:set_loader`
pub(crate) fn minijinja_path_loader(lua: &Lua) -> Result<LuaFunction, LuaError> {
    lua.load(
        r#"
        local function path_loader(paths)
            if type(paths) == "string" then
                paths = { paths }
            end

            local function loader(name)
                if name:match("\\") then return nil end

                name = name:gsub("^/+", ""):gsub("/+$", "")

                local sep = package.config:sub(1,1)
                local pattern = "([^" .. sep .. "]*)"

                local splits = {}
                for piece in name:gmatch(pattern) do
                    if ".." == piece then return nil end
                    table.insert(splits, piece)
                end

                for _, path in ipairs(paths) do
                    local p = path .. sep .. table.concat(splits, sep)
                    local file = io.open(p, "r")

                    if file then
                        local source = file:read("a")
                        file:close()

                        return source
                    end
                end
            end

            return loader
        end

        return path_loader
    "#,
    )
    .eval()
}

#[cfg(test)]
mod test {
    use mlua::Lua;

    use super::*;
    use crate::state::JinjaState;

    fn setup() -> Lua {
        Lua::new()
    }

    #[test]
    fn test_minijinja_types_environment() {
        let lua = setup();
        let env = lua.create_userdata(LuaEnvironment::new()).unwrap();

        assert_eq!(
            minijinja_types(&LuaValue::UserData(env)).unwrap(),
            "environment"
        );
    }

    #[test]
    fn test_minijinja_types_state() {
        let lua = setup();
        let env = minijinja::Environment::new();
        let state = env.empty_state();

        lua.scope(|scope| {
            let ud = scope.create_userdata(JinjaState::new(&state)).unwrap();
            assert_eq!(minijinja_types(&LuaValue::UserData(ud)).unwrap(), "state");
            Ok(())
        })
        .unwrap();
    }

    #[test]
    fn test_minijinja_types_none() {
        assert_eq!(minijinja_types(&LuaValue::NULL).unwrap(), "none");
    }

    #[test]
    fn test_minijinja_types_lua() {
        let lua = setup();

        assert_eq!(minijinja_types(&LuaValue::Nil).unwrap(), "nil");
        assert_eq!(
            minijinja_types(&LuaValue::Boolean(true)).unwrap(),
            "boolean"
        );
        assert_eq!(
            minijinja_types(&LuaValue::Function(
                lua.create_function(|_, _: LuaValue| Ok(())).unwrap()
            ))
            .unwrap(),
            "function"
        );
        assert_eq!(minijinja_types(&LuaValue::Integer(99)).unwrap(), "integer");
        assert_eq!(minijinja_types(&LuaValue::Number(99.99)).unwrap(), "number");
        assert_eq!(
            minijinja_types(&LuaValue::String(lua.create_string("foo").unwrap())).unwrap(),
            "string"
        );
        assert_eq!(
            minijinja_types(&LuaValue::Table(lua.create_table().unwrap())).unwrap(),
            "table"
        );
        assert_eq!(
            minijinja_types(&LuaValue::Thread(
                lua.create_thread(lua.create_function(|_, _: LuaValue| Ok(())).unwrap())
                    .unwrap()
            ))
            .unwrap(),
            "thread"
        );
    }
}
