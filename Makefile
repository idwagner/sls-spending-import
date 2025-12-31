SHELL := /bin/bash

all: build-lambda-layer
.PHONY: clean

# variables / macros
PWD := $(shell pwd)
BUILD_DIR := ${PWD}/build
date := $(shell which gdate || which date)
UV_SOURCE_DATE_EPOCH := $(shell \
	if git ls-files --error-unmatch uv.lock >/dev/null 2>&1 && git diff --quiet -- uv.lock >/dev/null 2>&1; then \
		git log -1 --format=%ct -- uv.lock 2>/dev/null; \
	else \
		python3 -c 'import os,sys;print(int(os.path.getmtime("uv.lock")))' 2>/dev/null || stat -c %Y uv.lock 2>/dev/null || stat -f %m uv.lock 2>/dev/null || date +%s; \
	fi)
UV_TOUCH_DATE := $(shell ${date} -d @${UV_SOURCE_DATE_EPOCH} +%Y-%m-%dT%H:%M:%S)
package_version := $(shell uv version --short)
PYTHON_VERSION := 3.14

build-lambda-layer: ${BUILD_DIR}/.build-lambda-layer-${UV_SOURCE_DATE_EPOCH}

${BUILD_DIR}/.build-lambda-layer-${UV_SOURCE_DATE_EPOCH}:
	uv sync
	mkdir -p ${BUILD_DIR}/python

	uv export --frozen --no-dev | pip3 install \
		--target ${BUILD_DIR}/python \
		--platform manylinux2014_x86_64 \
		--python-version ${PYTHON_VERSION} \
		--only-binary=:all: \
		-r <(uv export --frozen --no-dev -q --no-hashes --no-emit-local)

	find ${BUILD_DIR}/python -exec touch -d ${UV_TOUCH_DATE} {} +
	touch $@


clean:
	rm -rf build
