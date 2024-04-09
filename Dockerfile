# Use Ubuntu as the base image
FROM ubuntu:20.04 as builder

# Update package index and install necessary dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openjdk-11-jre-headless \
    curl \
    vim \
    wget \
    software-properties-common \
    ssh \
    net-tools \
    ca-certificates \
    python3 \
    python3-pip \
    python3-numpy \
    python3-matplotlib \
    python3-scipy \
    python3-pandas \
    python3-simpy \
    && rm -rf /var/lib/apt/lists/*

# Set Python3 as the default Python version
RUN update-alternatives --install "/usr/bin/python" "python" "$(which python3)" 1

# Set environment variables for Spark and Hadoop versions
ENV SPARK_VERSION=3.4.0 \
    HADOOP_VERSION=3 \
    SPARK_HOME=/opt/spark \
    PYTHONHASHSEED=1

# Download and extract Spark from Apache archive
RUN wget --no-verbose -O apache-spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mkdir -p /opt/spark && \
    tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 && \
    rm apache-spark.tgz
localhost
# Install Jupyter and its dependencies
RUN pip3 install --no-cache-dir jupyter

# Set up the Spark environment
FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_PORT=7077 \
    SPARK_MASTER_WEBUI_PORT=8080 \
    SPARK_LOG_DIR=/opt/spark/logs \
    SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
    SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out \
    SPARK_WORKER_WEBUI_PORT=8080 \
    SPARK_WORKER_PORT=7000 \
    SPARK_MASTER="spark://spark-master:7077" \
    SPARK_WORKLOAD="master"

EXPOSE 8080 7077 6066 8888

# Create log directory and files, and link to stdout
RUN mkdir -p $SPARK_LOG_DIR && \
    touch $SPARK_MASTER_LOG && \
    touch $SPARK_WORKER_LOG && \
    ln -sf /dev/stdout $SPARK_MASTER_LOG && \
    ln -sf /dev/stdout $SPARK_WORKER_LOG

# Copy startup script
COPY start-spark.sh /

CMD ["/bin/bash", "/start-spark.sh"]
