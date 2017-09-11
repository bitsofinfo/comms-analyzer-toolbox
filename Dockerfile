FROM centos:latest

EXPOSE 5601

ENV ES_VERSION 5.6.0
ENV KIBANA_VERSION 5.6.0

RUN yum -y install epel-release && yum clean all
RUN yum -y install zip unzip curl git java-1.8.0-openjdk python python-pip && yum clean all

RUN pip install beautifulsoup4
RUN pip install tornado

RUN mkdir /toolbox

ADD kibana.yml /toolbox
RUN useradd -r elasticsearch

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.zip && \
    unzip elasticsearch-${ES_VERSION}.zip && \
    rm -rf elasticsearch-${ES_VERSION}.zip && \
    ln -s elasticsearch-${ES_VERSION} elasticsearch && \
    chown -R elasticsearch elasticsearch-${ES_VERSION}

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    tar -xvf kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    rm -rf kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    ln -s kibana-${KIBANA_VERSION}-linux-x86_64 kibana && \
    chown -R elasticsearch kibana-${KIBANA_VERSION}-linux-x86_64

RUN cd /toolbox && git clone https://github.com/oliver006/elasticsearch-gmail.git

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#CMD ["python","/toolbox/elasticsearch-gmail/src/index_emails.py"]
