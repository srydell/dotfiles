return {
  s(
    { trig = 'cls', wordTrig = true, dscr = 'Class' },
    fmta(
      [[
        public class <> {
          <>
        }
      ]],
      {
        i(1, 'MyClass'),
        i(0),
      }
    )
  ),
  s(
    { trig = 'p', wordTrig = true, dscr = 'Print stuff' },
    fmta(
      [[
        System.out.println(<>);
      ]],
      {
        i(1),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if (<>) {
          <>
        }
      ]],
      {
        i(1, 'true'),
        i(0),
      }
    )
  ),
  s(
    { trig = 'ae', wordTrig = true, dscr = 'assertEquals' },
    fmta(
      [[
        assertEquals(<>, <>);
      ]],
      {
        i(1, '0'),
        i(2, '0'),
      }
    )
  ),
}
