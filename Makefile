.DEFAULT_GOAL := all

SHELL := /bin/bash

WITH_LUAJIT ?=
MACOSX_DEPLOYMENT_TARGET ?= 10.14

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

root := $(makefile_dir)

arch := $(shell uname -m)
nproc := $(shell getconf _NPROCESSORS_ONLN)

prefix ?= $(abspath $(root)/usr)

configure_configs := $(strip \
   -C \
   --prefix='$(prefix)' \
)

gettext_version := 0.22.5
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

lua_version := 5.4.7
luajit_version := 2.1.ROLLING

vim_version := 9.1.1415
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
  --disable-libsodium \
  --with-compiledby=sasa+1 \
  --with-features=huge \
  --with-lua-prefix='$(prefix)' \
  --without-x \
  --with-tlib=ncurses \
)

ifneq ($(WITH_LUAJIT),)
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
ifeq ($(findstring --with-luajit,$(vim_configs)),--with-luajit)
install: download-luajit install-luajit
else
install: download-lua install-lua
endif
install: download-vim install-vim postinstall-vim

.PHONY: download-gettext
download-gettext: ## [subtarget] download gettext archive
	curl -L -o '$(root)/usr/src/gettext-$(gettext_version).tar.xz' https://ftp.gnu.org/pub/gnu/gettext/gettext-$(gettext_version).tar.xz

.PHONY: download-lua
download-lua: ## [subtarget] download Lua archive
	curl -L -o '$(root)/usr/src/lua-$(lua_version).tar.gz' https://www.lua.org/ftp/lua-$(lua_version).tar.gz

.PHONY: download-luajit
download-luajit: ## [subtarget] download LuaJIT archive
	curl -L -o '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v$(luajit_version).tar.gz

.PHONY: download-vim
download-vim: ## [subtarget] download Vim archive
	curl -L -o '$(root)/usr/src/v$(vim_version).tar.gz' https://github.com/vim/vim/archive/v$(vim_version).tar.gz

.PHONY: install-gettext
install-gettext: ## [subtarget] install gettext
	$(RM) -r '$(root)/usr/src/gettext-$(gettext_version)'
	tar fvx '$(root)/usr/src/gettext-$(gettext_version).tar.xz' -C '$(root)/usr/src'
	cd '$(root)/usr/src/gettext-$(gettext_version)' && ./configure $(configure_configs) $(gettext_configs)
	make -j$(nproc) -C '$(root)/usr/src/gettext-$(gettext_version)'
	make install -C '$(root)/usr/src/gettext-$(gettext_version)'

.PHONY: install-lua
install-lua: ## [subtarget] install Lua
	$(RM) -r '$(root)/usr/src/lua-$(lua_version)'
	tar fvx '$(root)/usr/src/lua-$(lua_version).tar.gz' -C '$(root)/usr/src'
	make all install INSTALL_TOP='$(prefix)' -C '$(root)/usr/src/lua-$(lua_version)'

.PHONY: install-luajit
install-luajit: luajit_name := luajit-$(subst .ROLLING,,$(luajit_version))
install-luajit: ## [subtarget] install LuaJIT
	$(RM) -r '$(root)/usr/src/LuaJIT-$(luajit_version)'
	tar fvx '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' -C '$(root)/usr/src'
	sed -i.bak -e '/-DLUAJIT_ENABLE_LUA52COMPAT/s/^#//' '$(root)/usr/src/LuaJIT-$(luajit_version)/Makefile'
	MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET) make -C '$(root)/usr/src/LuaJIT-$(luajit_version)'
	make install PREFIX='$(prefix)' -C '$(root)/usr/src/LuaJIT-$(luajit_version)'
	ln -sf '$(prefix)/bin/$(luajit_name).' '$(prefix)/bin/luajit'
	# why can't vim find lua.h with -I option in build?
	cp '$(prefix)/include/$(luajit_name)/lua.h' '$(prefix)/include'

.PHONY: install-vim
install-vim: CFLAGS := -I$(prefix)/include
ifeq ($(findstring --with-luajit,$(vim_configs)),--with-luajit)
install-vim: CFLAGS += -I$(prefix)/include/luajit-$(subst .ROLLING,,$(luajit_version))
endif
install-vim: LDFLAGS := -L$(prefix)/lib -Wl,-rpath,'@executable_path/../lib'
install-vim: ## [subtarget] install Vim
	$(RM) -r '$(root)/usr/src/vim-$(vim_version)'
	tar fvx '$(root)/usr/src/v$(vim_version).tar.gz' -C '$(root)/usr/src/'
	cd '$(root)/usr/src/vim-$(vim_version)' && CFLAGS='$(CFLAGS)' LDFLAGS="$(LDFLAGS)" PATH='$(prefix)/bin':$$PATH ./configure $(configure_configs) $(vim_configs)
	make -j$(nproc) -C '$(root)/usr/src/vim-$(vim_version)'
	make install -C '$(root)/usr/src/vim-$(vim_version)'

# BUG: $(shell find) is evaluate in first time
# # fail:
# $ make install
# # success:
# $ make install
# $ make postinstall-vim
.PHONY: postinstall-vim
postinstall-vim: exe_file := $(shell find '$(abspath $(prefix)/bin)' -type f -perm -111 -print)
postinstall-vim: arg_file := $(shell mktemp)
postinstall-vim: awk_find := /(libluajit|macos-vim).*\.dylib/ { print $$1 }
postinstall-vim: awk_args := BEGIN { FS = "/"; OFS = "" } { print $$0, " ", "@executable_path/../", $$(NF-1), "/", $$(NF) }
postinstall-vim: ## [subtarget] rewrite dylib paths
	echo '$(exe_file)' | xargs otool -L | awk '$(awk_find)' | sort -u | awk '$(awk_args)' > '$(arg_file)'
	$(foreach file,$(exe_file),while read -r old new; do install_name_tool -change "$$old" "$$new" '$(file)'; done < '$(arg_file)';)
