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

/// This filter allows loading minijinja objects from a JSON string.
///
/// In Lua, this allows loading a json object while preserving key order.
#[cfg(feature = "json")]
pub(crate) mod json {
    use minijinja::{Error as JinjaError, ErrorKind as JinjaErrorKind, State, Value as JinjaValue};

    use crate::convert::err_to_minijinja_err;

    pub(crate) fn minijinja_filter_from_json(env: &mut minijinja::Environment) {
        env.add_filter(
            "fromjson",
            |_: &State, json: &[u8]| -> Result<JinjaValue, JinjaError> {
                serde_json::from_slice(json)
                    .map_err(|err| err_to_minijinja_err(err, JinjaErrorKind::BadSerialization))
            },
        )
    }
}

/// These filters allow formatting date and time strings using strftime style formats.
#[cfg(feature = "datetime")]
pub(crate) mod datetime {
    use jiff::civil::{Date, Time};
    use minijinja::{
        Error as JinjaError,
        ErrorKind as JinjaErrorKind,
        State,
        Value as JinjaValue,
        value::Kwargs,
    };

    use crate::convert::err_to_minijinja_err;

    /// Default date formats if none are provided to the filter.
    const DATE_FORMATS: &[&str] = &[
        "%m/%d/%Y",      // 01/01/2000
        "%m/%d/%y",      // 01/01/00
        "%B %d, %Y",     // January 01, 2000
        "%b %d, %Y",     // Jan 01, 2000
        "%B %d %Y",      // January 01 2000
        "%b %d %Y",      // Jan 01 2000
        "%A %B %d %Y",   // Monday January 01 2000
        "%A, %B %d, %Y", // Monday, January 01, 2000
        "%a %B %d %Y",   // Mon January 01 2000
        "%a, %B %d, %Y", // Mon, January 01, 2000
        "%A %b %d %Y",   // Monday Jan 01 2000
        "%A, %b %d, %Y", // Monday, Jan 01, 2000
        "%a %b %d %Y",   // Mon Jan 01 2000
        "%a, %b %d, %Y", // Mon, Jan 01, 2000
    ];

    /// Default time formats if none are provided to the filter.
    const TIME_FORMATS: &[&str] = &[
        "%I%t%p",       // 11 pm or 11pm
        "%I%t%P",       // 11 PM or 11PM
        "%H:%M",        // 23:00
        "%H:%M:%S",     // 23:00:00
        "%I:%M%t%p",    // 11:00 pm or 11:00pm
        "%I:%M%t%P",    // 11:00 PM or 11:00PM
        "%I:%M:%S%t%p", // 11:00:00 pm or 11:00:00pm
        "%I:%M:%S%t%P", // 11:00:00 PM or 11:00:00PM
    ];

    /// Formats a string into a date using the `jiff` crate.
    ///
    /// If `format` is provided, the date will be formatted according to the `strftime` format.
    /// Otherwise, the value from `jiff::civil::Date::to_string` is returned.
    ///
    /// If `patterns` is provided, it must be a list of `strptime` format strings to parse the
    /// input. Multiple patterns can be provided to allow support for various date formats. If no
    /// patterns are provided, the patterns in [`DATE_FORMATS`] are used.
    ///
    /// The input is first parsed by calling `.parse()`. If this fails, each pattern in `patterns`
    /// is attempted in order. The first successful match is the parsed time.
    pub(crate) fn minijinja_filter_format_date(env: &mut minijinja::Environment) {
        env.add_filter(
            "datefmt",
            |_: &State, value: JinjaValue, kwargs: Kwargs| -> Result<String, JinjaError> {
                let format = kwargs.get::<Option<&str>>("format")?;
                let patterns = kwargs.get::<Option<Vec<String>>>("patterns")?.unwrap_or(
                    DATE_FORMATS
                        .iter()
                        .map(|p| p.to_string())
                        .collect::<Vec<String>>(),
                );
                kwargs.assert_all_used()?;

                let date = match value.as_str() {
                    Some(s) => s.parse::<Date>().or_else(|_| {
                        patterns
                            .iter()
                            .find_map(|f| Date::strptime(f, s).ok())
                            .ok_or(jiff::Error::from_args(format_args!(
                                "could not parse value as a date: {}",
                                s
                            )))
                    }),
                    None => Err(JinjaError::new(
                        JinjaErrorKind::CannotDeserialize,
                        "could not parse value as a string",
                    ))?,
                }
                .map_err(|err| err_to_minijinja_err(err, JinjaErrorKind::CannotDeserialize))?;

                match format {
                    Some(f) => Ok(date.strftime(f).to_string()),
                    None => Ok(date.to_string()),
                }
            },
        );
    }

    /// Formats a string into a time using the `jiff` crate.
    ///
    /// If `format` is provided, the time will be formatted according to the `strftime` format.
    /// Otherwise, the value from `jiff::civil::Time::to_string` is returned.
    ///
    /// If `patterns` is provided, it must be a list of `strptime` format strings to parse the
    /// input. Multiple patterns can be provided to allow support for various date formats. If no
    /// patterns are provided, the patterns in [`TIME_FORMATS`] are used.
    ///
    /// The input is first parsed by calling `.parse()`. If this fails, each pattern in `patterns`
    /// is attempted in order. The first successful match is the parsed time.
    pub(crate) fn minijinja_filter_format_time(env: &mut minijinja::Environment) {
        env.add_filter(
            "timefmt",
            |_: &State, value: JinjaValue, kwargs: Kwargs| -> Result<String, JinjaError> {
                let format = kwargs.get::<Option<&str>>("format")?;
                let patterns = kwargs.get::<Option<Vec<String>>>("patterns")?.unwrap_or(
                    TIME_FORMATS
                        .iter()
                        .map(|p| p.to_string())
                        .collect::<Vec<String>>(),
                );
                kwargs.assert_all_used()?;

                let time = match value.as_str() {
                    Some(s) => s.parse::<Time>().or_else(|_| {
                        patterns
                            .iter()
                            .find_map(|f| Time::strptime(f, s).ok())
                            .ok_or(jiff::Error::from_args(format_args!(
                                "could not parse value as a time: {}",
                                s
                            )))
                    }),
                    None => Err(JinjaError::new(
                        JinjaErrorKind::CannotDeserialize,
                        "could not parse value as a string",
                    ))?,
                }
                .map_err(|err| err_to_minijinja_err(err, JinjaErrorKind::CannotDeserialize))?;

                match format {
                    Some(f) => Ok(time.strftime(f).to_string()),
                    None => Ok(time.to_string()),
                }
            },
        );
    }
}

#[cfg(test)]
mod test {
    use minijinja::context;
    use mlua::Lua;
    use serde_json::json;

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

    #[test]
    #[cfg(feature = "json")]
    fn test_minijinja_from_json_filter() {
        let mut env = minijinja::Environment::new();
        json::minijinja_filter_from_json(&mut env);

        let ex = json!({"1": 1, "2": 2, "three": [1,2,3]});
        let expr = env.compile_expression("te | fromjson").unwrap();

        let res = expr.eval(context! { te => ex.to_string() }).unwrap();

        assert_eq!(res, minijinja::Value::from_serialize(ex));
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_datefmt_filter() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_date(&mut env);

        let tests = [
            ("12/31/2000", "2000-12-31"),
            ("12/31/00", "0000-12-31"),
            ("December 31, 2000", "2000-12-31"),
            ("Dec 31, 2000", "2000-12-31"),
            ("December 31 2000", "2000-12-31"),
            ("Dec 31 2000", "2000-12-31"),
            ("Sunday December 31 2000", "2000-12-31"),
            ("Sunday, December 31, 2000", "2000-12-31"),
            ("Sun December 31 2000", "2000-12-31"),
            ("Sun, December 31, 2000", "2000-12-31"),
            ("Sunday Dec 31 2000", "2000-12-31"),
            ("Sunday, Dec 31, 2000", "2000-12-31"),
            ("Sun Dec 31 2000", "2000-12-31"),
            ("Sun, Dec 31, 2000", "2000-12-31"),
        ];

        for (te, ex) in tests {
            let expr = env.compile_expression("te | datefmt").unwrap();
            let res = expr.eval(context! { te => te }).unwrap();

            assert_eq!(res.as_str().unwrap(), ex, "{} should parse to {}", te, ex);
        }
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_datefmt_filter_format() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_date(&mut env);

        let date = "January 1, 2026";
        let fmt = "%B %-d, %Y";

        let te = format!("te | datefmt(format='{}')", fmt);
        let expr = env.compile_expression(&te).unwrap();

        let res = expr.eval(context! { te => date }).unwrap();

        assert_eq!(res.as_str().unwrap(), "January 1, 2026");
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_datefmt_filter_parse() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_date(&mut env);

        let date = "2026 1 January";
        let patt = "%Y %-d %B";

        let te = format!("te | datefmt(patterns=['{}'])", patt);
        let expr = env.compile_expression(&te).unwrap();

        let res = expr.eval(context! { te => date }).unwrap();

        assert_eq!(res.as_str().unwrap(), "2026-01-01");
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_timefmt_filter() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_time(&mut env);

        let tests = [
            ("11 pm", "23:00:00"),
            ("11pm", "23:00:00"),
            ("11 PM", "23:00:00"),
            ("11PM", "23:00:00"),
            ("23:15", "23:15:00"),
            ("23:15:00", "23:15:00"),
            ("11:15 pm", "23:15:00"),
            ("11:15pm", "23:15:00"),
            ("11:15 PM", "23:15:00"),
            ("11:15PM", "23:15:00"),
            ("11:15:00 pm", "23:15:00"),
            ("11:15:00pm", "23:15:00"),
            ("11:15:00 PM", "23:15:00"),
            ("11:15:00PM", "23:15:00"),
        ];

        for (te, ex) in tests {
            let expr = env.compile_expression("te | timefmt").unwrap();
            let res = expr.eval(context! { te => te }).unwrap();

            assert_eq!(res.as_str().unwrap(), ex, "{} should parse to {}", te, ex);
        }
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_timefmt_filter_format() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_time(&mut env);

        let time = "12:02:31";
        let fmt = "%S:%M:%H";

        let te = format!("te | timefmt(format='{}')", fmt);
        let expr = env.compile_expression(&te).unwrap();

        let res = expr.eval(context! { te => time }).unwrap();

        assert_eq!(res.as_str().unwrap(), "31:02:12");
    }

    #[test]
    #[cfg(feature = "datetime")]
    fn test_minijinja_timefmt_filter_parse() {
        let mut env = minijinja::Environment::new();
        datetime::minijinja_filter_format_time(&mut env);

        let time = "04 02 09";
        let patt = "%M %H %S";

        let te = format!("te | timefmt(patterns=['{}'])", patt);
        let expr = env.compile_expression(&te).unwrap();

        let res = expr.eval(context! { te => time }).unwrap();

        assert_eq!(res.as_str().unwrap(), "02:04:09");
    }
}
