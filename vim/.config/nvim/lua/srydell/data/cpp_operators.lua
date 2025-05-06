local ls = require('luasnip')
local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
-- local r = ls.restore_node
-- local events = require('luasnip.util.events')
-- local ai = require('luasnip.nodes.absolute_indexer')
local extras = require('luasnip.extras')
-- local l = extras.lambda
local rep = extras.rep
-- local p = extras.partial
-- local m = extras.match
-- local n = extras.nonempty
-- local dl = extras.dynamic_lambda
-- local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
-- local conds = require('luasnip.extras.expand_conditions')
-- local postfix = require('luasnip.extras.postfix').postfix
-- local types = require('luasnip.util.types')
-- local parse = require('luasnip.util.parser').parse_snippet
-- local ms = ls.multi_snippet
-- local k = require('luasnip.nodes.key_indexer').new_key

local function get_surrounding_classname()
  local class = require('srydell.treesitter.cpp').get_class_name_under_cursor()
  if class then
    return sn(nil, { t(class) })
  end
  return sn(nil, { i(1, 'Class') })
end

return {
  ['+'] = sn(
    nil,
    fmta(
      [[
      friend <> operator+(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['-'] = sn(
    nil,
    fmta(
      [[
      friend <> operator-(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['*'] = sn(
    nil,
    fmta(
      [[
      friend <> operator*(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['/'] = sn(
    nil,
    fmta(
      [[
      friend <> operator/(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['%'] = sn(
    nil,
    fmta(
      [[
      friend <> operator%(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['^'] = sn(
    nil,
    fmta(
      [[
      friend <> operator^(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['&'] = sn(
    nil,
    fmta(
      [[
      friend <> operator&(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['|'] = sn(
    nil,
    fmta(
      [[
      friend <> operator|(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['~'] = sn(
    nil,
    fmta(
      [[
      friend <> operator~(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['!'] = sn(
    nil,
    fmta(
      [[
      friend <> operator!(<> lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        i(2),
      }
    )
  ),
  ['='] = sn(
    nil,
    fmta(
      [[
      <>& operator=(<> const& other)
      {
        <>
        return *this;
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['<'] = sn(
    nil,
    fmta(
      [[
      friend bool operator<<(<> const& l, <> const& r)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['>'] = sn(
    nil,
    fmta(
      [[
      friend bool operator>>(<> const& l, <> const& r)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['<='] = sn(
    nil,
    fmta(
      [[
      friend bool operator<<=(<> const& l, <> const& r)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['>='] = sn(
    nil,
    fmta(
      [[
      friend bool operator>>=(<> const& l, <> const& r)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['+='] = sn(
    nil,
    fmta(
      [[
      <>& operator+=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['-='] = sn(
    nil,
    fmta(
      [[
      <>& operator-=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['*='] = sn(
    nil,
    fmta(
      [[
      <>& operator*=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['/='] = sn(
    nil,
    fmta(
      [[
      <>& operator/=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['%='] = sn(
    nil,
    fmta(
      [[
      <>& operator%=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['^='] = sn(
    nil,
    fmta(
      [[
      <>& operator^=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['&='] = sn(
    nil,
    fmta(
      [[
      <>& operator&=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['|='] = sn(
    nil,
    fmta(
      [[
      <>& operator|=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['<<'] = sn(
    nil,
    fmta(
      [[
      std::ostream& operator<<<<(std::ostream& os, <> const& obj)
      {
        // write obj to stream
        <>
        return os;
      }
      ]],
      {
        d(1, get_surrounding_classname),
        i(2),
      }
    )
  ),
  ['>>'] = sn(
    nil,
    fmta(
      [[
      std::istream& operator>>>>(std::istream& is, <>& obj)
      {
        // read obj from stream
        <>
        if (/* <> could not be constructed */)
            is.setstate(std::ios::failbit);
        return is;
      }
      ]],
      {
        d(1, get_surrounding_classname),
        i(2),
        rep(1),
      }
    )
  ),
  ['>>='] = sn(
    nil,
    fmta(
      [[
      <>& operator >>>>=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['<<='] = sn(
    nil,
    fmta(
      [[
      <>& operator <<<<=(const <>& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['=='] = sn(
    nil,
    fmta(
      [[
      inline bool operator==(const <>& lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['!='] = sn(
    nil,
    fmta(
      [[
      inline bool operator!=(const <>& lhs, <> const& rhs)
      {
        <>
      }
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        i(2),
      }
    )
  ),
  ['++'] = sn(
    nil,
    c(1, {
      sn(
        nil,
        fmta(
          [[
            // prefix increment
            <>& operator++()
            {
              <>
              return *this;
            }
          ]],
          {
            d(1, get_surrounding_classname),
            i(2),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            // postfix increment
            <> operator++(int)
            {
              <>
            }
          ]],
          {
            d(1, get_surrounding_classname),
            i(2),
          }
        )
      ),
    })
  ),
  ['--'] = sn(
    nil,
    c(1, {
      sn(
        nil,
        fmta(
          [[
            // prefix increment
            <>& operator--()
            {
              <>
              return *this;
            }
          ]],
          {
            d(1, get_surrounding_classname),
            i(2),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            // postfix increment
            <> operator--(int)
            {
              <>
            }
          ]],
          {
            d(1, get_surrounding_classname),
            i(2),
          }
        )
      ),
    })
  ),
  ['()'] = sn(
    nil,
    fmta(
      [[
      <> operator()(<>)
      {
        <>
      }
      ]],
      {
        i(1, 'void'),
        i(2),
        i(3),
      }
    )
  ),
  ['[]'] = sn(
    nil,
    fmta(
      [[
      <> operator[](<>)
      {
        <>
      }
      ]],
      {
        i(1, 'void'),
        i(2),
        i(3),
      }
    )
  ),
  -- Who does these?
  -- [','] = 'hi',
  -- ['->*'] = 'hi',
  -- ['->'] = 'hi',
  -- ['<=>'] = 'hi',
  -- ['&&'] = 'hi',
  -- ['||'] = 'hi',
}
