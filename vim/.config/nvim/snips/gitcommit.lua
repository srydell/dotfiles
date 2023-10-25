local function get_branch_name()
  local branch = io.popen('git branch --show-current'):read()
  local output = branch
  -- Get the last one separated by '/'
  -- E.g. origin/feature/NCM-1438 -> NCM-1438
  for block in string.gmatch(branch, '[^/]+') do
    output = block
  end
  return output
end

local function get_issue_summary()
  local branch = get_branch_name()
  local output = io.popen(
    string.format([[
    curl --silent --request GET \
      -H "Authorization: Bearer $JIRA_API_TOKEN" \
      --url "https://jira.global.org.nasdaqomx.com/rest/api/2/issue/%s" | jq --raw-output '.fields.summary'
    ]], branch)
  ):read()

  return output
end

return
{
  s(
    { trig='commit', wordTrig=true, dscr='Commit message' },
    fmta(
      [[
        <>: <>
      ]],
      {
        f(get_branch_name, {}, {}),
        f(get_issue_summary, {}, {}),
      }
    )
  ),
}
