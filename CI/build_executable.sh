#!/bin/bash

pushd third_party

./scripts/export_vtube_project.sh

popd

cp ./CI/vtube_project.sh ./bin/

