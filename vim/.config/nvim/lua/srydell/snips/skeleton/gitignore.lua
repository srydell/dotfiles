local function skeleton()
  return s(
    { trig = 'skeleton', dscr = 'Skeleton snippet' },
    fmta(
      [[
        # Ignore everything
        /*

        # Ignore all files named (wherever they are):
        .DS_Store
        .log

        # Except these
        # Files
        <>

        # Directories
      ]],
      {
        i(0),
      }
    )
  )
end

return {
  snip = skeleton(),
}
