.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

root := $(makefile_dir)

arch := $(shell uname -m)

prefix ?= $(abspath $(root)/usr)

gettext_version := 0.21
gettext_configs := $(strip \
   --enable-option-checking \
   --disable-dependency-tracking \
   --disable-java \
   --disable-csharp \
   --disable-largefile \
   --enable-fast-install \
   --disable-c++ \
   --enable-cross-guesses \
   --enable-relocatable \
   --without-emacs \
   --without-lispdir \
   --without-git \
   --without-cvs \
   --without-bzip2 \
   --without-xz \
)

lua_version := 5.4.3
luajit_version := 2.0.5

vim_version := 9.0.1199
vim_configs := $(strip \
  --enable-fail-if-missing \
  --disable-smack \
  --disable-selinux \
  --disable-xsmp \
  --disable-xsmp-interact \
  --enable-luainterp=yes \
  --enable-cscope \
  --disable-netbeans \
  --enable-terminal \
  --enable-multibyte \
  --disable-rightleft \
  --disable-arabic \
  --enable-gui=no \
  --with-compiledby=sasa+1 \
  --with-features=huge \
  --with-lua-prefix='$(prefix)' \
  --without-x \
  --with-tlib=ncurses \
)

ifneq ($(arch),arm64)
  vim_configs += --with-luajit
endif

.PHONY: all
all: ## output targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(makefile) | awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

.PHONY: clean
clean: ## remove files
	$(RM) -r $(root)/usr/bin/* $(root)/usr/include/* $(root)/usr/lib/* $(root)/usr/man/* $(root)/usr/share/* $(root)/usr/src/*

.PHONY: install
install: ## install Vim and some additinal components
install: download-gettext install-gettext
install: download-lua install-lua
ifneq ($(arch),arm64)
install: download-luajit install-luajit
endif
install: download-vim install-vim

.PHONY: download-gettext
download-gettext: ## [subtarget] download gettext archive
	curl -L -o '$(root)/usr/src/gettext-$(gettext_version).tar.xz' https://ftp.gnu.org/pub/gnu/gettext/gettext-$(gettext_version).tar.xz

.PHONY: download-lua
download-lua: ## [subtarget] download Lua archive
	curl -L -o '$(root)/usr/src/lua-$(lua_version).tar.gz' https://www.lua.org/ftp/lua-$(lua_version).tar.gz

.PHONY: download-luajit
download-luajit: ## [subtarget] download LuaJIT archive
	curl -L -o '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' https://luajit.org/download/LuaJIT-$(luajit_version).tar.gz

.PHONY: download-vim
download-vim: ## [subtarget] download Vim archive
	curl -L -o '$(root)/usr/src/v$(vim_version).tar.gz' https://github.com/vim/vim/archive/v$(vim_version).tar.gz

.PHONY: install-gettext
install-gettext: ## [subtarget] install gettext
	$(RM) -r '$(root)/usr/src/gettext-$(gettext_version)'
	tar fvx '$(root)/usr/src/gettext-$(gettext_version).tar.xz' -C '$(root)/usr/src'
	cd '$(root)/usr/src/gettext-$(gettext_version)' && ./configure --prefix='$(prefix)' $(gettext_configs)
	make -C '$(root)/usr/src/gettext-$(gettext_version)'
	make install -C '$(root)/usr/src/gettext-$(gettext_version)'

.PHONY: install-lua
install-lua: ## [subtarget] install Lua
	$(RM) -r '$(root)/usr/src/lua-$(lua_version)'
	tar fvx '$(root)/usr/src/lua-$(lua_version).tar.gz' -C '$(root)/usr/src'
	make all install INSTALL_TOP='$(prefix)' -C '$(root)/usr/src/lua-$(lua_version)'

.PHONY: install-luajit
install-luajit: ## [subtarget] install LuaJIT
	$(RM) -r '$(root)/usr/src/LuaJIT-$(luajit_version)'
	tar fvx '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' -C '$(root)/usr/src'
	MACOSX_DEPLOYMENT_TARGET=10.14 make -C '$(root)/usr/src/LuaJIT-$(luajit_version)'
	make install PREFIX='$(prefix)' -C '$(root)/usr/src/LuaJIT-$(luajit_version)'

.PHONY: install-vim
install-vim: ## [subtarget] install Vim
	$(RM) -r '$(root)/usr/src/vim-$(vim_version)'
	tar fvx '$(root)/usr/src/v$(vim_version).tar.gz' -C '$(root)/usr/src/'
	cd '$(root)/usr/src/vim-$(vim_version)' && CFLAGS='-I$(prefix)/include' LDFLAGS='-L$(prefix)/lib' PATH='$(prefix)/bin':$$PATH ./configure --prefix='$(prefix)' $(vim_configs)
	make -C '$(root)/usr/src/vim-$(vim_version)'
	make install -C '$(root)/usr/src/vim-$(vim_version)'
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libintl/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libintl.?.dylib)" '$(prefix)/bin/vim'
ifneq ($(arch),arm64)
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libluajit/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libluajit-?.?.?.dylib)" '$(prefix)/bin/vim'
endif
