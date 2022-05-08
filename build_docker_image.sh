#!/bin/bash
version=${1:-1.0.0}
echo "use version :$version"
# markdown local packages names,for reference later
echo '' > ./tar-source-files/file_list.txt
files=$(ls ./tar-source-files/)
for sfile in ${files}
do 
    echo $sfile >> ./tar-source-files/file_list.txt
done
docker build -t lisacumt/zeppelin-bigdata-centos-docker:$version .
