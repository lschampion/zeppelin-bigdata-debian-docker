#!/bin/bash
version=${1:-1.0.0}
echo "use version :$version"
docker build -t lisacumt/zeppelin-bigdata-docker:$version .
