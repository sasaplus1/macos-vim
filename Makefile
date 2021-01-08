.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

root := $(makefile_dir)

vim_version := 8.2.2311

.PHONY: all
all: ## output targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(makefile) | awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

.PHONY: clean
clean: ## remove files
	$(RM) $(root)/usr/bin/* $(root)/usr/lib/* $(root)/usr/share/* $(root)/usr/src/*

.PHONY: download-vim
download-vim: ## download Vim archive
	curl -L -o '$(root)/usr/src/v$(vim_version).tar.gz' https://github.com/vim/vim/archive/v$(vim_version).tar.gz

.PHONY: install-vim
install-vim: ## install Vim
	tar fvx '$(root)/usr/src/v$(vim_version).tar.gz' -C '$(root)/usr/src/'
	cd '$(root)/usr/src/vim-$(vim_version)' && ./configure --prefix='$(root)/usr'
	make -C '$(root)/usr/src/vim-$(vim_version)'
	make install -C '$(root)/usr/src/vim-$(vim_version)'
