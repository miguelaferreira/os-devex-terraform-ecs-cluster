#!/usr/bin/env sh

set -e

if [ -f ".env" ]; then
  source .env
fi

set -v

VERSION_FILE="version.txt"

VERSION=$( cat ${VERSION_FILE} )
git tag --annotate v${VERSION} --message "Release v${VERSION}"
git push --tags

if [ -z "$( git branch | grep '^* master$' )" ]; then
  # Checkout master
  git branch -d master
  git fetch origin master:master
  git checkout master
fi

bump.sh ${VERSION} > ${VERSION_FILE}
git add ${VERSION_FILE}
git commit -m "Incremented version from ${VERSION} to $( cat ${VERSION_FILE} ) [skip ci]"
git push origin master
