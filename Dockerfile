FROM ubuntu:artful
WORKDIR /vimpager
ADD . /vimpager
RUN apt-get -qqy update
RUN apt-get -qqy install vim make sudo git bats lintian
RUN git clean -dxf || true
RUN git fetch --unshallow --tags || true
RUN make build-deb-deps
