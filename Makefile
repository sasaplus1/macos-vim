.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

root := $(makefile_dir)

prefix := $(abspath $(root)/usr)

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
	$(RM) $(root)/usr/bin/* $(root)/usr/lib/* $(root)/usr/share/* $(root)/usr/src/*

.PHONY: download-luajit
download-luajit: ## download LuaJIT archive
	curl -L -o '$(root)/usr/src/LuaJIT-$(luajit_version).tar.gz' https://luajit.org/download/LuaJIT-$(luajit_version).tar.gz

.PHONY: download-vim
download-vim: ## download Vim archive
	curl -L -o '$(root)/usr/src/v$(vim_version).tar.gz' https://github.com/vim/vim/archive/v$(vim_version).tar.gz

.PHONY: install
install: ## install Vim and LuaJIT
install: download-luajit install-luajit
install: download-vim install-vim

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
	cd '$(root)/usr/src/vim-$(vim_version)' && ./configure --prefix='$(prefix)' $(vim_configs)
	make -C '$(root)/usr/src/vim-$(vim_version)'
	make install -C '$(root)/usr/src/vim-$(vim_version)'
