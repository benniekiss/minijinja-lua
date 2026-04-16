local filter = require("minijinja_filter")

describe("Examples", function()
    describe("pandoc#examples", function()
        it("minijinja filter#examples", function()
            local source = [[
---
minijinja:
    context:
        foo: "BOO"
---

Test: {{ foo }}
]]
            local doc = pandoc.read(source, "markdown")

            local te = doc:walk(filter)
            local ex = pandoc.read(
                [=[[ Para [ Str "$dollar",Space,Str "dollar",Space,Str "bills${test",Space,Str "string}[]" ]]]=],
                "native"
            )

            assert.Equal(ex, te)
        end)
    end)
end)
