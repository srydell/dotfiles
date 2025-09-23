local helpers = require('srydell.snips.helpers')

local get_visual = helpers.get_visual

return {
  s(
    { trig = 'extends', wordTrig = true, dscr = 'Extend block' },
    fmta(
      [[
        {% extends "<>.html" %}
      ]],
      {
        i(1),
      }
    )
  ),

  s(
    { trig = 'block', wordTrig = true, dscr = 'Block' },
    fmta(
      [[
        {% block <> %}
          <><>
        {% endblock %}
      ]],
      {
        i(1, 'block_name'),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'f', wordTrig = true, dscr = 'Function' },
    fmta(
      [[
      {% macro <>(<>) -%}
        <><>
      {%- endmacro %}
      ]],
      {
        i(1, 'f'),
        i(2),
        d(3, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'for', wordTrig = true, dscr = 'For loop' },
    fmta(
      [[
        {% for <> in <> %}
          <><>
        {% endfor %}
      ]],
      {
        i(1, 'variable'),
        i(2, '[1, 2, 3]'),
        d(3, get_visual),
        i(0),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        {% if <> %}
          <><>
        {% endif %}
      ]],
      {
        i(1, 'False'),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'block', wordTrig = true, dscr = 'block' },
    fmta(
      [[
        {% block <> %}<>{% endblock %}
      ]],
      {
        i(1, 'content'),
        i(2),
      }
    )
  ),

  s(
    { trig = 'extends', wordTrig = true, dscr = 'extends block' },
    fmta(
      [[
        {% extends '<>.html' %}
      ]],
      {
        i(1, 'base'),
      }
    )
  ),
}
