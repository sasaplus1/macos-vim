# macos-vim

[![Actions Status: test](https://github.com/sasaplus1/macos-vim/workflows/test/badge.svg)](https://github.com/sasaplus1/macos-vim/actions?query=workflow%3A"test")

my Vim for macOS

## How to install

```console
$ make install
```

if you want to change install directory:

```console
$ make install prefix=/path/to/dir
```

if you want LuaJIT:

```console
$ WITH_LUAJIT=1 make install
```

see `Makefile` for more details.

## License

The MIT license.
