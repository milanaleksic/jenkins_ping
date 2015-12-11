APP_NAME := jenkins_ping
GOPATH := ${GOPATH}
SOURCEDIR = .

SOURCES := $(shell find $(SOURCEDIR) -name '*.go')

.DEFAULT_GOAL: ${APP_NAME}

${APP_NAME}: $(SOURCES)
	go get ./...
	go build -o ${APP_NAME}

.PHONY: deploy
deploy: $(SOURCES)
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN parameter must be set)
endif
ifndef TAG
	$(error TAG parameter must be set)
endif
	echo Creating and pushing tag
	git tag ${TAG}
	git push --tags
	echo Sleeping 5 seconds before trying to create release...
	sleep 5
	echo Creating release
	github-release release -u milanaleksic -r ${APP_NAME} --tag "${TAG}" --name "v${TAG}"

	echo Building and shipping Windows
	GOOS=windows go build
	upx ${APP_NAME}.exe
	github-release upload -u milanaleksic -r ${APP_NAME} --tag ${TAG} --name "${APP_NAME}-${TAG}-windows-amd64.exe" -f ${APP_NAME}.exe

	echo Building and shipping Linux
	GOOS=linux go build
	goupx ${APP_NAME}
	github-release upload -u milanaleksic -r ${APP_NAME} --tag ${TAG} --name "${APP_NAME}-${TAG}-linux-amd64" -f ${APP_NAME}

.PHONY: run
run: ${APP_NAME}
	${APP_NAME}

.PHONY: test
test:
	go test

.PHONY: ci
ci: $(SOURCES)
	go build -o ${APP_NAME}

.PHONY: prepare
prepare: ${GOPATH}/bin/github-release \
	${GOPATH}/bin/goupx \
	${GOPATH}/src/github.com/conformal/gotk3 \
	${GOPATH}/src/github.com/jroimartin/gocui \
	${GOPATH}/src/github.com/mgutz/ansi \
	${GOPATH}/src/github.com/skratchdot/open-golang/ \
	gtk \
	upx

${GOPATH}/bin/goupx:
	go get github.com/pwaller/goupx

${GOPATH}/bin/github-release:
	go get github.com/aktau/github-release

${GOPATH}/src/github.com/conformal/gotk3:
	go get -tags gtk_3_10 github.com/conformal/gotk3/gtk

${GOPATH}/src/github.com/jroimartin/gocui:
	go get github.com/jroimartin/gocui

${GOPATH}/src/github.com/mgutz/ansi:
	go get github.com/mgutz/ansi

${GOPATH}/src/github.com/skratchdot/open-golang/:
	go get github.com/skratchdot/open-golang/open

.PHONE: upx
upx:
	curl http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 | tar xjvf - && mv upx-3.91-amd64_linux/upx upx && rm -rf upx-3.91-amd64_linux

.PHONE: gtk
gtk:
	dpkg -s libgtk-3-dev   > /dev/null || libgtk-3-dev
	dpkg -s libcairo2-dev  > /dev/null || libcairo2-dev
	dpkg -s libglib2.0-dev > /dev/null || libglib2.0-dev
	dpkg -s gtk+3.0        > /dev/null || gtk+3.0

.PHONY: clean
clean:
	rm -rf ${APP_NAME}
	rm -rf ${APP_NAME}.exe