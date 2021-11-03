# Trouble with Homebrew and `pkg-config`


`pkg-config` is small utility that allows asking installed libraries about their configuration. This is very useful for compiling software that depends on them. It allows automated scripts to work on different platforms/distributions without detailed knowledge of library installation path and include directory layout. There's more details on [Wikipedia](https://en.wikipedia.org/wiki/Pkg-config).

When one uses [Homebrew](https://brew.sh) to install [Sundials library](https://formulae.brew.sh/formula/sundials) on macOS, it doesn't come with support for `pkg-config`. I'm not sure if this is a feature or a bug, but that's how it is. In order to overcome this and allow SPM to link with Sundials, the repository contains a custom configuration that can be used as a substitute. It's placed in [`Config/libsundials.pc`](Config/libsundials.pc) and has been tested on macOS 11 and 12.


## Lookup procedure of `pkg-config` 

When `pkg-config` is asked to lookup information about a particular library, it it scans a list of directories for the matching `*.pc` file. Once the corresponding `*.pc` file is located, `pkg-config` simply retrieves the values written there. The directory list is formatted the same way as the `PATH` variable and can be printed via

```sh
$> pkg-config --variable pc_path pkg-config
/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/local/Homebrew/Library/Homebrew/os/mac/pkgconfig/10.15
```

The `PKG_CONFIG_PATH` environmental variable can be used to temporarily add a directory to the list. Once the variable has been set, the following command can be used to verify functionality.

```sh
$> PKG_CONFIG_PATH=./Config pkg-config --debug --libs libsundials
...
Parsing package file './Config/libsundials.pc'
  line>prefix=/usr/local/opt/sundials
 Variable declaration, 'prefix' has value '/usr/local/opt/sundials'
  line>exec_prefix=${prefix}
 Variable declaration, 'exec_prefix' has value '/usr/local/opt/sundials'
  line>libdir=${exec_prefix}/lib
 Variable declaration, 'libdir' has value '/usr/local/opt/sundials/lib'
  line>includedir=${prefix}/include
 Variable declaration, 'includedir' has value '/usr/local/opt/sundials/include'
...
```


## Using Swift Package Manager

Using the `PKG_CONFIG_PATH` variable is the fastest way to get started. Run the following command from the root of the repository

```sh
$> PKG_CONFIG_PATH=./Config swift build
```


## Using Xcode

Building in Xcode is trickier because it's harder to see whether `pkg-config` is setup correctly. The error messages tend to be somewhat misleading. There are two ways to build the package. Option **A** is good for a one-off compilation and **B** works better for long term development because the setup persists across sessions.

- **A** - Export `PKG_CONFIG_PATH` variable and make it point to the `./Config` directory and then start Xcode from the same console.

- **B** - Copy `./Config/libsundials.pc` to one of the directories printed by `pkg-config --variable pc_path pkg-config` command. This most likely requires elevated permissions.
