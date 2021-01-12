.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

root := $(makefile_dir)

prefix := $(abspath $(root)/usr)

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

lua_version := 5.4.2
luajit_version := 2.0.5

vim_version := 8.2.2311
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
  --with-luajit \
  --without-x \
  --with-tlib=ncurses \
)

.PHONY: all
all: ## output targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(makefile) | awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

.PHONY: clean
clean: ## remove files
	$(RM) -r $(root)/usr/bin/* $(root)/usr/include/* $(root)/usr/lib/* $(root)/usr/man/* $(root)/usr/share/* $(root)/usr/src/*

.PHONY: download-gettext
download-gettext: ## download gettext archive
	curl -L -o '$(root)/usr/src/gettext-$(gettext_version).tar.xz' https://ftp.gnu.org/pub/gnu/gettext/gettext-$(gettext_version).tar.xz

.PHONY: download-lua
download-lua: ## download Lua archive
	curl -L -o '$(root)/usr/src/lua-$(lua_version).tar.gz' https://www.lua.org/ftp/lua-$(lua_version).tar.gz

.PHONY: download-luajit
download-luajit: ## download LuaJIT archive
	curl -L -o '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' https://luajit.org/download/LuaJIT-$(luajit_version).tar.gz

.PHONY: download-vim
download-vim: ## download Vim archive
	curl -L -o '$(root)/usr/src/v$(vim_version).tar.gz' https://github.com/vim/vim/archive/v$(vim_version).tar.gz

.PHONY: install-default-vim
install-default-vim: ## install Vim and some additinal components
install-default-vim: download-gettext install-gettext
install-default-vim: download-lua install-lua
install-default-vim: download-luajit install-luajit
install-default-vim: download-vim install-vim

.PHONY: install-kaoriya-vim
install-kaoriya-vim: ## install KaoriYa Vim and some additional components
install-kaoriya-vim: download-gettext install-gettext
install-kaoriya-vim: download-lua install-lua
install-kaoriya-vim: download-luajit install-luajit
install-kaoriya-vim: install-vim-kaoriya

.PHONY: install-gettext
install-gettext: ## install gettext
	$(RM) -r '$(root)/usr/src/gettext-$(gettext_version)'
	tar fvx '$(root)/usr/src/gettext-$(gettext_version).tar.xz' -C '$(root)/usr/src'
	cd '$(root)/usr/src/gettext-$(gettext_version)' && ./configure --prefix='$(prefix)' $(gettext_configs)
	make -C '$(root)/usr/src/gettext-$(gettext_version)'
	make install -C '$(root)/usr/src/gettext-$(gettext_version)'

.PHONY: install-lua
install-lua: ## install Lua
	$(RM) -r '$(root)/usr/src/lua-$(lua_version)'
	tar fvx '$(root)/usr/src/lua-$(lua_version).tar.gz' -C '$(root)/usr/src'
	make all install INSTALL_TOP='$(prefix)' -C '$(root)/usr/src/lua-$(lua_version)'

.PHONY: install-luajit
install-luajit: ## install LuaJIT
	$(RM) -r '$(root)/usr/src/LuaJIT-$(luajit_version)'
	tar fvx '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' -C '$(root)/usr/src'
	MACOSX_DEPLOYMENT_TARGET=10.14 make -C '$(root)/usr/src/LuaJIT-$(luajit_version)'
	make install PREFIX='$(prefix)' -C '$(root)/usr/src/LuaJIT-$(luajit_version)'

.PHONY: install-vim
install-vim: ## install Vim
	$(RM) -r '$(root)/usr/src/vim-$(vim_version)'
	tar fvx '$(root)/usr/src/v$(vim_version).tar.gz' -C '$(root)/usr/src/'
	cd '$(root)/usr/src/vim-$(vim_version)' && CFLAGS='-I$(prefix)/include' LDFLAGS='-L$(prefix)/lib' PATH='$(prefix)/bin':$$PATH ./configure --prefix='$(prefix)' $(vim_configs)
	make -C '$(root)/usr/src/vim-$(vim_version)'
	make install -C '$(root)/usr/src/vim-$(vim_version)'
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libintl/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libintl.?.dylib)" '$(prefix)/bin/vim'
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libluajit/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libluajit-?.?.?.dylib)" '$(prefix)/bin/vim'

.PHONY: install-vim-kaoriya
install-vim-kaoriya: ## install KaoriYa Vim
	git clone --depth 1 https://github.com/koron/guilt.git '$(root)/usr/src/guilt'
	git clone --depth 1 https://github.com/koron/vim-kaoriya.git '$(root)/usr/src/vim-kaoriya'
	git clone --depth 1 https://github.com/ko1nksm/readlinkf '$(root)/usr/src/readlinkf'
	cd '$(root)/usr/src/vim-kaoriya' && git submodule update --depth 1 --init --recommend-shallow --recursive -- ./contrib/vimdoc-ja ./patches ./vim
	awk '$$1 ~ /^VIM_VER$$/ { print $$3 }' '$(root)/usr/src/vim-kaoriya/VERSION' > '$(root)/usr/src/vim-kaoriya/VIM_VER'
	sed -i.bak -e 's|readlink -f|"$(root)/usr/src/readlinkf/readlinkf_posix"|g' '$(root)/usr/src/guilt/guilt'
	make install PREFIX='$(root)/usr' -C '$(root)/usr/src/guilt'
	cd '$(root)/usr/src/vim-kaoriya/vim' && git checkout -b v$$(cat '$(root)/usr/src/vim-kaoriya/VIM_VER')
	cd '$(root)/usr/src/vim-kaoriya/vim' && git config --local guilt.patchesdir ../patches
	cd '$(root)/usr/src/vim-kaoriya/vim' && PATH='$(root)/usr/bin':$$PATH guilt init
	cd '$(root)/usr/src/vim-kaoriya' && cp ./patches/master/* "./patches/v$$(cat '$(root)/usr/src/vim-kaoriya/VIM_VER')"
	cd '$(root)/usr/src/vim-kaoriya/vim/src' && PATH='$(root)/usr/bin':$$PATH guilt push --all
	make autoconf -C '$(root)/usr/src/vim-kaoriya/vim/src'
	cd '$(root)/usr/src/vim-kaoriya/vim' && CFLAGS='-I$(prefix)/include' LDFLAGS='-L$(prefix)/lib' PATH='$(prefix)/bin':$$PATH ./configure --prefix='$(prefix)' $(vim_configs)
	make -C '$(root)/usr/src/vim-kaoriya/vim'
	make install -C '$(root)/usr/src/vim-kaoriya/vim'
	sed -i.bak -e "s|-o \{1,\}root|-o $$(whoami)|g" '$(root)/usr/src/vim-kaoriya/build/freebsd/Makefile'
	make kaoriya-install -C '$(root)/usr/src/vim-kaoriya/build/freebsd'
	cp -rf '$(root)/usr/src/vim-kaoriya/contrib/vimdoc-ja' '$(root)/usr/share/vim/plugins'
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libintl/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libintl.?.dylib)" '$(prefix)/bin/vim'
	install_name_tool -change "$$(otool -L '$(prefix)/bin/vim' | awk '/libluajit/ { print $$1 }')" "$$(ls -1 '$(prefix)'/lib/libluajit-?.?.?.dylib)" '$(prefix)/bin/vim'
