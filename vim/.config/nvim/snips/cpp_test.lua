local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
local sn = ls.snippet_node
local i = ls.insert_node

return {
  s({ trig = 'require', wordTrig = true, dscr = 'Boost require' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE(<>);
          ]],
          { r(1, 'comparison') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_EQUAL(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_GE(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_LE(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['comparison'] = i(1, 'true'),
      ['other'] = i(2),
    },
  }),

  s(
    { trig = 'expect', wordTrig = true, dscr = 'GMock Expect' },
    fmta(
      [[
        EXPECT_CALL(<>, <>(<>)).WillOnce(Return(<>));
      ]],
      {
        i(1, 'mock'),
        i(2, 'f'),
        i(3),
        i(4),
      }
    )
  ),

  s(
    { trig = 'test', wordTrig = true, dscr = 'Test case' },
    fmta(
      [[
        BOOST_AUTO_TEST_CASE(<>)
        {
          <>
        }
      ]],
      {
        i(1, 'name_of_the_test'),
        i(0),
      }
    )
  ),
}
