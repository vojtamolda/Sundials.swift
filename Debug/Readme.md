#  Extending LLDB


One of the more obscure but very useful features of LLDB is its ability to be scripted in Python. LLDB includes automatically generated Python bindings to its original C++ API. Extending LLDB with Python allows one to reduce repetitive commands into a single action, and expose a whole new level of power that you can use to improve your debugging productivity.

The `LLDB.py` file contains "debugging sugar" that makes squashing bugs in code that uses this library a little easier. It leverages the Python API to provide custom summaries and synthetic children. Or in other words, it makes the `Vector` and `Matrix` types much more pleasant and user-friendly. Their content can be checked at a glance in XCode's Variable View just like the built-in `Array` type.

More details about the LLDB Python API and its usage can be found in [this article][LLDB Python Scripting]. Full reference documentation for the entire API is hosted [here][LLDB Python API].


## Embedded Python

The embedded Python interpreter can be accessed directly from within LLDB console. Command `script` launches an interactive REPL. See [this article][LLDB Python Reference] for a comprehensive overview of available objects and their methods.

```
(lldb) script
```

Turning on the magical summaries and synthetic children requires executing the code from `LLDB.py` script within the builtin Python interpreter. The following command does the trick:

```
(lldb) command script import /path/to/this/repo/Debug/LLDB.py
```


## Automatic Startup

Custom summaries don't persist across LLDB sessions. The `LLDB.py` script has to be executed at the beginning of every debugging session. Here are two convenient ways to do it.

- **Add XCode breakpoint with custom action**

  Xcode allows attaching custom LLDB commands to every breakpoint. Place a breakpoint near the start of the code that is being debugged. Then attach `command script import LLDB.py` action and enable the continue after execution to prevent the application from stopping here.

- **Add command to `.lldbinit` file**

  At startup, LLDB looks for an initialization file to execute. Adding the `command script import LLDB.py` line to the file will automatically load the "debugging sugar" for every session. First file that LLDB reads is `~/.lldbinit`. Alternatively, there is also `~/.lldbinit-Xcode` which is only sourced when Xcode is run or `~/.lldbinit-lldb` that is sourced only when `lldb` is started directly from the command line. 


## Other Resources

Here's a few useful links to WWDC sessions that focus on LLDB.

- WWDC 2018 Session 412: Advanced Debugging with Xcode and LLDB - https://developer.apple.com/wwdc18/412
- LLDB: Beyond "po" - https://developer.apple.com/videos/play/wwdc2019/429/
- Discover breakpoint improvements - https://developer.apple.com/videos/play/wwdc2021/10209




[LLDB Python API]: https://lldb.llvm.org/python_api.html
[LLDB Python Scripting]: https://lldb.llvm.org/use/python.html
[LLDB Python Reference]: https://lldb.llvm.org/use/python-reference.html
