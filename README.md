# Big data playground: Zeppelin

Zeppelin Docker image built on top of **[hadoop-hive-hbase-spark-docker](https://github.com/lschampion/hadoop-hive-hbase-spark-docker)**

## Software

* [Zeppelin 0.9.0](https://zeppelin.apache.org/docs/0.9.0/) 

## Usage

Take a look [at this repo](https://github.com/lschampion/bigdata-docker-compose)
to see how I use it as a part of a Docker Compose cluster.

`.conf/interpreter.json` 

store datasoure and interpreter config

## Maintaining

* Docker file code linting:  `docker run --rm -i hadolint/hadolint < Dockerfile`
* [To trim the fat from Docker image](https://github.com/wagoodman/dive)
