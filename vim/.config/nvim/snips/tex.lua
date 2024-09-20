return {
  s(
    { trig = 'eq', wordTrig = true, dscr = 'equation' },
    fmta(
      [[
        \begin{equation}
          <>
        \end{equation}
      ]],
      {
        i(0),
      }
    )
  ),
  s(
    { trig = 'list', wordTrig = true, dscr = 'List of items' },
    fmta(
      [[
        \begin{itemize}
          \item <>
        \end{itemize}
      ]],
      {
        i(0),
      }
    )
  ),
  s(
    { trig = 'fig', wordTrig = true, dscr = 'figure' },
    fmta(
      [[
        \begin{figure}[h]
          \includegraphics[width=0.5\textwidth]{<>}
          \centering
        \end{figure}
      ]],
      {
        i(1),
      }
    )
  ),
  s(
    { trig = 'sec', wordTrig = true, dscr = 'Section' },
    fmta(
      [[
        \section{<>}
      ]],
      {
        i(1),
      }
    )
  ),

  s(
    { trig = 'frame', wordTrig = true, dscr = 'frame' },
    fmta(
      [[
        \begin{frame}
          <>
        \end{frame}
      ]],
      {
        i(0),
      }
    )
  ),

  s(
    { trig = 'columns', wordTrig = true, dscr = 'columns' },
    fmta(
      [[
        \begin{columns}
          \column{0.5\textwidth}
          <>
          \column{0.5\textwidth}
          <>
        \end{columns}
      ]],
      {
        i(1),
        i(0),
      }
    )
  ),
}
