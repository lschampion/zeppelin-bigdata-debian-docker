FROM lisacumt/bigdata_base_env_centos_img:1.2.0 as env_package

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV ZEPPELIN_VERSION=0.10.1
ENV ZEPPELIN_HOME=/usr/program/zeppelin
ENV ZEPPELIN_PACKAGE="zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz"
ENV PATH="${PATH}:${ZEPPELIN_HOME}/bin"
ENV MASTER=yarn-client
ENV ZEPPELIN_CONF_DIR="${ZEPPELIN_HOME}/conf"
ENV ZEPPELIN_ADDR=0.0.0.0
ENV ZEPPELIN_PORT=8890
ENV ZEPPELIN_NOTEBOOK_DIR="/zeppelin_notebooks"


###########################################################################################
FROM env_package as application_package

ENV USR_PROGRAM_DIR=/usr/program
ENV USR_BIN_DIR="${USR_PROGRAM_DIR}/source_dir"
RUN mkdir -p "${USR_BIN_DIR}"
# 使用本地的源文件，加快rebuild速度，方便调试
COPY tar-source-files/* "${USR_PROGRAM_DIR}/source_dir"/
WORKDIR "${USR_PROGRAM_DIR}/source_dir"

# jansi-2.4.0.jar hive使用tez计算引擎会报错。缺少jansi的类。
# 国内加速地址，注意版本不全
# https://mirrors.aliyun.com/apache/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz
# 如果${USR_PROGRAM_DIR}/source_dir不存在，则下载
RUN if [ ! -f "${ZEPPELIN_PACKAGE}" ]; then curl --progress-bar -L --retry 3 \
    "https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/${ZEPPELIN_PACKAGE}" \
	-o "${USR_PROGRAM_DIR}/source_dir/${ZEPPELIN_PACKAGE}" ; fi \
	&& tar -xf "${ZEPPELIN_PACKAGE}" -C "${USR_PROGRAM_DIR}" \
    && mv "${USR_PROGRAM_DIR}/zeppelin-${ZEPPELIN_VERSION}-bin-all" "${ZEPPELIN_HOME}" \
    && chown -R root:root "${ZEPPELIN_HOME}" \
	&& cp "${USR_PROGRAM_DIR}/source_dir/jansi-2.4.0.jar" "${ZEPPELIN_HOME}/lib"/ \
    && rm -rf "${USR_PROGRAM_DIR}/source_dir/*"

COPY conf/interpreter.json "${ZEPPELIN_CONF_DIR}"
COPY jdbc_drivers/* "${ZEPPELIN_HOME}/interpreter/jdbc"/


# Clean up
RUN rm -rf "${ZEPPELIN_HOME}/interpreter/alluxio" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/angular" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/bigquery" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/cassandra" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/elasticsearch" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/flink" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/groovy" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/hbase" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/ignite" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/kylin" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/lens" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/neo4j" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/pig" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/sap" \
    && rm -rf "${ZEPPELIN_HOME}/interpreter/scio"

###########################################################################################
FROM env_package 
COPY --from=application_package "${ZEPPELIN_HOME}"/ "${ZEPPELIN_HOME}"/

RUN mkdir -p "${HADOOP_CONF_DIR}" && mkdir -p "${HIVE_CONF_DIR}" && mkdir -p "${HBASE_CONF_DIR}" && mkdir -p "${SPARK_CONF_DIR}" 
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${HBASE_CONF_DIR}"/ "${HBASE_CONF_DIR}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${HADOOP_HOME}"/ "${HADOOP_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${HIVE_HOME}"/ "${HIVE_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${SPARK_HOME}"/ "${SPARK_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${TEZ_HOME}"/ "${TEZ_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${FLINK_HOME}"/ "${FLINK_HOME}"/
COPY --from=lisacumt/hadoop-hive-hbase-spark-docker:1.1.6 "${HIVE_HOME}/jdbc/hive-jdbc-${HIVE_VERSION}-standalone.jar" "${ZEPPELIN_HOME}/interpreter/jdbc"/


HEALTHCHECK CMD curl -f "http://host.docker.internal:${ZEPPELIN_PORT}/" || exit 1

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
