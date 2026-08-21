-- Exercises the full sanitizer ingestion path shared by tsan/asan/lsan/ubsan:
--   tools/filter_<sanitizer>.py --as-json  ->  vim.json.decode  ->
--   srydell.util.sanitizer.load_into_quickfix_from_json  ->  quickfix list
--
-- Run with:
-- nvim --headless -u init.lua -l tests/sanitizer_quickfix_ingest.lua

local sanitizer = require('srydell.util.sanitizer')

local config_root = vim.fn.stdpath('config')

local function tools_script(name)
  return config_root .. '/tools/' .. name
end

local function run_filter(script, log_path, ...)
  local cmd = { 'python3', tools_script(script), '--filename', log_path }
  for _, extra in ipairs({ ... }) do
    table.insert(cmd, extra)
  end
  local output = vim.fn.system(cmd)
  assert(vim.v.shell_error == 0, script .. ' exited with an error: ' .. output)
  return output
end

local function decode_json(raw, context)
  local ok, decoded = pcall(vim.json.decode, raw, { luanil = { object = true, array = true } })
  assert(ok, context .. ' did not produce valid JSON: ' .. raw)
  return decoded
end

--------------------------------------------------------------------------
-- TSAN: the fullest test, covering the get_valid_file() path-resolution
-- rules (build-relative "../" paths, the "../source" -> "../oal" fallback,
-- and unresolvable paths) as well as quickfix navigation helpers.
--------------------------------------------------------------------------

local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')

-- Layout:
--   root/build            (cwd when the "tsan.log" is filtered/loaded)
--   root/build/src/foo_thread.cpp   (resolves "../src/foo_thread.cpp")
--   root/oal/src/bar_thread.cpp     (resolves "../source/src/bar_thread.cpp"
--                                    via the "../source" -> "../oal" fallback)
vim.fn.mkdir(root .. '/build/src', 'p')
vim.fn.mkdir(root .. '/oal/src', 'p')
vim.fn.writefile({ 'void foo_thread_run() {}' }, root .. '/build/src/foo_thread.cpp')
vim.fn.writefile({ 'void bar_thread_run() {}' }, root .. '/oal/src/bar_thread.cpp')

local tsan_log = table.concat({
  'WARNING: ThreadSanitizer: data race (pid=12345)',
  '  Write of size 4 at 0x7b0400000000 by thread T2 (mutexes: write M1):',
  '    #0 foo_thread_run() ../src/foo_thread.cpp:42 (mybinary+0x455f8)',
  '    #1 start_thread <null> (libpthread.so.0+0x76db)',
  '',
  '  Previous read of size 4 at 0x7b0400000000 by main thread:',
  '    #0 helper() ../source/src/bar_thread.cpp:7 (mybinary+0x1234)',
  '',
  "  Thread T2 'foo_thread' (tid=3164, running) created by main thread at:",
  '    #0 pthread_create <null> (libtsan.so.0+0x2f783)',
  '    #1 main() ../does/not/exist.cpp:8 (mybinary+0x1111)',
  '',
  'SUMMARY: ThreadSanitizer: data race ../src/foo_thread.cpp:42 in foo_thread_run()',
  '',
}, '\n')
vim.fn.writefile(vim.split(tsan_log, '\n'), root .. '/tsan.log')

vim.cmd.cd(root .. '/build')

local tsan_json = run_filter('filter_tsan.py', root .. '/tsan.log', '--as-json')
local tsan_decoded = decode_json(tsan_json, 'filter_tsan.py --as-json')
assert(#tsan_decoded == 1, 'expected exactly one TSAN warning, got ' .. #tsan_decoded)

local tsan_warning = tsan_decoded[1]
assert(#tsan_warning.stacks == 3, 'expected 3 stacks (write, read, thread-created), got ' .. #tsan_warning.stacks)
assert(
  tsan_warning.stacks[3].header:match("^Thread T2 'foo_thread'") ~= nil,
  'the final "Thread ... created by" stack must not be dropped from the JSON'
)

sanitizer.load_into_quickfix_from_json(tsan_decoded, 'TSAN output')

local qflist = vim.fn.getqflist()
assert(#qflist > 0, 'quickfix list should be populated after ingesting TSAN JSON')

local function find_item(list, predicate)
  for _, item in ipairs(list) do
    if predicate(item) then
      return item
    end
  end
  return nil
end

-- The overall warning line should be the first entry.
assert(qflist[1].text:match('^WARNING: ThreadSanitizer: data race') ~= nil, 'first item should be the warning line')

-- setqflist resolves a given `filename` into a `bufnr`, so getqflist()
-- reports the buffer, not the original path string.
local function bufname_of(item)
  if item.bufnr == 0 then
    return nil
  end
  return vim.fn.bufname(item.bufnr)
end

-- A frame whose file exists relative to cwd ("../src/foo_thread.cpp") should
-- resolve to a real, jumpable quickfix entry with a valid buffer + lnum set.
local foo_frame = find_item(qflist, function(item)
  return item.text and item.text:match('^#0 foo_thread_run%(%)$') ~= nil
end)
assert(foo_frame ~= nil, 'expected a quickfix entry for the foo_thread_run frame')
assert(foo_frame.valid == 1, 'foo_thread_run frame should be a valid, jumpable quickfix entry')
assert(tostring(foo_frame.lnum) == '42', 'unexpected resolved line number: ' .. tostring(foo_frame.lnum))
local foo_bufname = bufname_of(foo_frame)
assert(
  foo_bufname ~= nil and foo_bufname:match('src/foo_thread%.cpp$'),
  'unexpected resolved filename: ' .. tostring(foo_bufname)
)
assert(vim.fn.filereadable(foo_bufname) == 1, 'resolved filename must actually be readable from cwd')

-- A frame using the "../source/..." -> "../oal/..." fallback resolution.
local bar_frame = find_item(qflist, function(item)
  return item.text and item.text:match('^#0 helper%(%)$') ~= nil
end)
assert(bar_frame ~= nil, 'expected a quickfix entry for the helper frame')
assert(bar_frame.valid == 1, 'helper frame should be a valid, jumpable quickfix entry')
assert(tostring(bar_frame.lnum) == '7', 'unexpected resolved line number: ' .. tostring(bar_frame.lnum))
local bar_bufname = bufname_of(bar_frame)
assert(
  bar_bufname ~= nil and bar_bufname:match('oal/src/bar_thread%.cpp$'),
  'unexpected resolved filename: ' .. tostring(bar_bufname)
)
assert(vim.fn.filereadable(bar_bufname) == 1, 'resolved fallback filename must actually be readable from cwd')

-- A frame pointing at a file that cannot be found anywhere should fall back
-- to embedding "filename:linenumber" in the text instead of a bogus filename.
local missing_frame = find_item(qflist, function(item)
  return item.text and item.text:match('does/not/exist%.cpp:8$') ~= nil
end)
assert(missing_frame ~= nil, 'expected a fallback text entry for the unresolvable frame')
assert(missing_frame.bufnr == 0, 'unresolvable frame must not be attached to a buffer')
assert(missing_frame.valid == 0, 'unresolvable frame must not be a jumpable quickfix entry')

-- The SUMMARY line should be the last entry.
assert(
  qflist[#qflist].text:match('^SUMMARY: ThreadSanitizer: data race') ~= nil,
  'last item should be the summary line'
)

-- Navigation helpers should be able to walk between stack sections and
-- between whole warnings.
vim.fn.setqflist({}, 'r', { id = vim.fn.getqflist({ id = 0 }).id, idx = 1 })
sanitizer.goto_next_stack()
local after_next_stack = vim.fn.getqflist({ idx = 0 }).idx
assert(after_next_stack > 1, 'goto_next_stack should move the quickfix cursor forward')

vim.fn.setqflist({}, 'r', { id = vim.fn.getqflist({ id = 0 }).id, idx = 1 })
sanitizer.goto_next_warning()
-- There is only one warning in this fixture, so the cursor should not move
-- past the end of the list (goto_warning bails out when it runs off).
local after_next_warning = vim.fn.getqflist({ idx = 0 }).idx
assert(after_next_warning >= 1, 'goto_next_warning should not error with a single warning')

--------------------------------------------------------------------------
-- ASAN / LSAN / UBSAN: a lighter smoke test per sanitizer, using absolute
-- paths (typical of these tools) to exercise the get_valid_file() direct
-- filereadable() check rather than the "../" build-relative walk-up.
--------------------------------------------------------------------------

local other_root = vim.fn.tempname()
vim.fn.mkdir(other_root .. '/src', 'p')
vim.fn.writefile({ 'int main() { return 0; }' }, other_root .. '/src/main.cpp')

local sanitizer_fixtures = {
  {
    script = 'filter_asan.py',
    title = 'ASAN output',
    log = table.concat({
      '==6226==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x1',
      'READ of size 4 at 0x1 thread T0',
      '    #0 0x417f8b in main ' .. other_root .. '/src/main.cpp:1',
      '',
      'SUMMARY: AddressSanitizer: heap-buffer-overflow main.cpp:1 in main',
      '',
    }, '\n'),
    warning_pattern = '^==6226==ERROR: AddressSanitizer:',
    summary_pattern = '^SUMMARY: AddressSanitizer:',
  },
  {
    script = 'filter_lsan.py',
    title = 'LSAN output',
    log = table.concat({
      '==1234==ERROR: LeakSanitizer: detected memory leaks',
      '',
      'Direct leak of 7 byte(s) in 1 object(s) allocated from:',
      '    #0 0x4af0ad in malloc',
      '    #1 0x4ea6e4 in main ' .. other_root .. '/src/main.cpp:1',
      '',
      'SUMMARY: LeakSanitizer: 7 byte(s) leaked in 1 allocation(s).',
      '',
    }, '\n'),
    warning_pattern = '^==1234==ERROR: LeakSanitizer:',
    summary_pattern = '^SUMMARY: LeakSanitizer:',
  },
  {
    script = 'filter_ubsan.py',
    title = 'UBSAN output',
    log = table.concat({
      other_root .. '/src/main.cpp:1:5: runtime error: some undefined behavior',
      '    #0 0x1 in main ' .. other_root .. '/src/main.cpp:1',
      '',
      'SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior main.cpp:1:5 in main',
      '',
    }, '\n'),
    warning_pattern = ': runtime error: ',
    summary_pattern = '^SUMMARY: UndefinedBehaviorSanitizer:',
  },
}

for _, fixture in ipairs(sanitizer_fixtures) do
  local log_path = other_root .. '/' .. fixture.script .. '.log'
  vim.fn.writefile(vim.split(fixture.log, '\n'), log_path)

  local raw_json = run_filter(fixture.script, log_path, '--as-json')
  local decoded = decode_json(raw_json, fixture.script .. ' --as-json')
  assert(#decoded == 1, fixture.script .. ': expected exactly one report, got ' .. #decoded)
  assert(#decoded[1].stacks >= 1, fixture.script .. ': expected at least one stack')

  sanitizer.load_into_quickfix_from_json(decoded, fixture.title)
  local list = vim.fn.getqflist()
  assert(#list > 0, fixture.script .. ': quickfix list should be populated')
  assert(list[1].text:match(fixture.warning_pattern) ~= nil, fixture.script .. ': first item should be the warning')
  assert(list[#list].text:match(fixture.summary_pattern) ~= nil, fixture.script .. ': last item should be the summary')

  -- The frame pointing at an absolute, real file must resolve to a valid,
  -- jumpable quickfix entry (exercising the direct filereadable() check).
  local resolved_frame = find_item(list, function(item)
    return item.valid == 1 and item.lnum == 1
  end)
  assert(resolved_frame ~= nil, fixture.script .. ': expected the main.cpp frame to resolve to a real buffer')
end

print('sanitizer_quickfix_ingest: ok')
