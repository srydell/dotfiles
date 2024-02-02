return {
  name = 'maven',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = {
        'clean',
        'install',
      },
      components = {
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = [==[[ERROR] %f:%l\,%c: %m,]==]
            .. [==[[ERROR] %f:[%l\,%v] %m,]==]
            .. [==[[%tRROR] %#Malformed POM %f: %m@%l:%c%.%#,]==]
            .. [==[[%tRROR] %#Non-parseable POM %f: %m %#\@ line %l\, column %c%.%#,]==]
            .. [==[[%[A-Z]%#] %f:[%l\,%c] %t%[a-z]%#: %m,]==]
            .. [==[[%t%[A-Z]%#] %f:[%l\,%c] %[%^:]%#: %m,]==]
            .. [==[%A[%[A-Z]%#] Exit code: %[0-9]%# - %f:%l: %m,]==]
            .. [==[%A[%[A-Z]%#] %f:%l: %m,]==]
            .. [==[%-Z[%[A-Z]%#] %p^,]==]
            .. [==[%C[%[A-Z]%#] %#%m]==],
          -- [ERROR] filename.java:[23,62] incompatible types: long cannot be converted to java.lang.String
          -- [ERROR] filename.java:9:8: Unused import - com.google.gson.JsonArray. [UnusedImports]
        },
        'default',
      },
    }
  end,
}
