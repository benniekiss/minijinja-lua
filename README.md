# minijinja-lua

![License](https://img.shields.io/github/license/benniekiss/minijinja-lua)
![Version](https://img.shields.io/github/v/release/benniekiss/minijinja-lua)
[![LuaRocks](https://img.shields.io/luarocks/v/benniekiss/minijinja-lua)](https://luarocks.org/modules/benniekiss/minijinja-lua)

*A Lua module for [`minijinja`](https://github.com/mitsuhiko/minijinja) via
[`mlua`](https://github.com/mlua-rs/mlua) bindings*

## Installation

```shell
# with lux
lx install minijinja-lua

# with luarocks
luarocks install minijinja-lua
```

## Usage

```lua
mj = require("minijinja")

env = mj.Environment:new()

env:add_template("my_temp", "Test: {{ foo | lua_filter }}")

local function lua_filter(state, val)
    return val:upper()
end

env:add_filter("lua_filter", lua_filter)

local ctx = {
    foo = "foo"
}

env:render_template("my_temp", ctx)
-- output: "Test: FOO"
```

The API is documented in the `library/minijinja.lua` file, which should work with LuaLS
or EmmyluaLS.

For more information, review the [`minijinja`](https://docs.rs/minijinja/latest/minijinja/index.html) documentation:

- [syntax](https://docs.rs/minijinja/latest/minijinja/syntax/index.html)
- [filters](https://docs.rs/minijinja/latest/minijinja/filters/index.html)
- [tests](https://docs.rs/minijinja/latest/minijinja/tests/index.html)
- [functions](https://docs.rs/minijinja/latest/minijinja/functions/index.html)

## Development

### Contributing

Contributions are welcome! Feel free to open bug reports, feature requests, or
PRs.

#### AI Policy

AI is not allowed for communication, such as PR or issue report body content.

#### Getting Started

This project uses the nightly rust toolchain and the
[lux](https://github.com/lumen-oss/lux) package manager for development.
Pre-commit hooks are provided through [`prek`](https://github.com/j178/prek).

If you do not already have rust installed, you can find [directions
here](https://rust-lang.org/tools/install/)

To install `lux`, follow the [directions
here](https://lux.lumen-labs.org/tutorial/getting-started)

To install `prek`, follow the [directions
here](https://prek.j178.dev/installation/)

##### Setup

```shell
# Clone the repo
git clone https://github.com/benniekiss/minijinja-lua
cd minijinja-lua

# Install the toolchain for the project
rustup install

# If you need to install lux
cargo install lux-cli
lx sync

# If you need to install prek
cargo install prek
prek install-hooks
```

### Linting and Formatting

Make sure to run `cargo fmt`, `cargo check`, and `cargo clippy` prior to any
submissions.

### Tests

Lua tests are within the `spec/` directory and use
[`busted`](https://github.com/lunarmodules/busted). The tests can be run with
`lx test`

Rust unit tests can be run with `cargo test`.

### Building

To build the project as a lua module, run `lx build`, or `cargo build
--no-default-features --features module,lua{version}`, where `{version}` is one
of `55`, `54`, `53`, `52`, or `51`.

To build it as a library, run `cargo build`.

### Submitting PRs

Please follow the [Conventional Commits](https://www.conventionalcommits.org)
specification for PR titles.
