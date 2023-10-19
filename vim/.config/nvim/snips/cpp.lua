return {
  s({ trig='^(%s*)i', regTrig=true, dscr='#include statement' },
    fmta(
      [[
        #include <>
      ]],
      {
        c(1, {
          isn(nil, { t('<'), r(1, 'include'), t('>') }, "    "),
          isn(nil, { t('"'), r(1, 'include'), t('"') }, "    "),
        }),
      }),
    {
      stored = {
          -- key passed to restoreNodes.
          ["include"] = i(1, "iostream")
      }
    }
  ),

  s(
    { trig='^(%s*)f', regTrig=true, dscr='Function' },
    fmta(
          [[
            <> <>(<>)
            {
              <>
            }
          ]],
          {
            i(1, 'int'),
            i(2, 'f'),
            i(3),
            i(4),
          }
      )
  ),

  s(
    { trig='for', wordTrig=true, dscr='for loop' },
      {
        c(1, {
          sn(nil, fmta( -- Ranged for loop
                [[
                  for (<> <> : <>) {
                    <>
                  }
                ]], { i(1, 'auto const&'), i(2, 'element'), i(3, 'container'), i(0) })),
          sn(nil, fmta( -- Indexed for loop
                [[
                  for (<> <> = 0; <> << <>; <>++) {
                    <>
                  }
                ]], { i(1, 'size_t'), i(2, 'i'), rep(2), i(3, 'count'), rep(2), i(4) })),
          sn(nil, fmta( -- Get '\n' terminated strings
                [[
                  for (std::string <>; std::getline(<>, <>);) {
                    <>
                  }
                ]], { i(1, 'line'), i(2, 'std::cin'), rep(1), i(3) })),
          sn(nil, fmta( -- Iterate over map
                [[
                  for (<> [<>, <>] : <>) {
                    <>
                  }
                ]], { i(1, 'auto const&'), i(2, 'key'), i(3, 'value'), i(4, 'map'), i(5) })),
        }),
      }
  ),

  s(
    { trig='if', wordTrig=true, dscr='if statement' },
      {
        c(1, {
          sn(nil, fmta(
                [[
                  if (<>) {
                    <>
                  }
                ]], { i(1), i(2) })),
          sn(nil, fmta(
                [[
                  std::smatch <>;
                  if (std::regex_search(<>, <>, <>) {
                    <>
                  }
                ]], { i(1, 'matches'), i(2, 'string_var'), rep(1), i(3, 'pattern'), i(4) })),
        }),
      }
  ),

}
