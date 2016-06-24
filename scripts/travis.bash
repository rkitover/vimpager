#!/usr/bin/env bash

# Script that collects different jobs to run on Travis.

set -e
set -o pipefail

osx () { [[ $TRAVIS_OS_NAME == osx ]]; }

case $1 in
  update)
    if osx; then
      brew update
    else
      # Update to a new version of lintian as the one on trusty is quite old.
      # This also runs apt-get update.
      scripts/update_lintian
    fi
    ;;
  dependencies)
    if osx; then
      brew install bats
    else
      # Install the test suite manually as there is no package for it on
      # trusty.
      git clone https://github.com/sstephenson/bats.git
      (
	cd bats
	./install.sh ~/.local
      )
      # The bats directory is only needed during the manual installation
      # above.  It would be reported by lintian otherwise.
      rm -fr bats
    fi
    ;;
  install-deb)
    if osx; then
      echo Nothing to do on OS X.
    else
      # The target install-deb also installs the sharutils package that
      # contains uuencode.  Without DEB_BUILD_OPTIONS=nocheck
      # dpkg-buildpackage (which is run by install-deb) would also run the
      # tests.
      sudo make install-deb CLEAN_BUILD_DEPS=0 DEB_BUILD_OPTIONS=nocheck
    fi
    ;;
  lint)
    if osx; then
      echo Nothing to lint on OS X.
    else
      # lintian has to be run after make install-deb as it needs the file that
      # are created by the makefile.
      lintian --profile debian -i --fail-on-warnings -EvIL +pedantic ../vimpager*.changes
    fi
    ;;
esac
