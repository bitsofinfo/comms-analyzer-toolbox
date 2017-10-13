FROM centos:latest

EXPOSE 9200
EXPOSE 5601

ENV ES_VERSION 5.6.3
ENV KIBANA_VERSION 5.6.3

RUN yum -y install epel-release && yum clean all
RUN yum -y install unzip zip curl git java-1.8.0-openjdk python python-pip && yum clean all

RUN pip install --upgrade pip
RUN pip install beautifulsoup4 python-dateutil html5lib lxml tornado retrying pyelasticsearch joblib click

RUN mkdir /toolbox
ADD kibana.yml /toolbox
RUN useradd -r elasticsearch

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.zip && \
    unzip elasticsearch-${ES_VERSION}.zip && \
    rm -rf elasticsearch-${ES_VERSION}.zip && \
    ln -s elasticsearch-${ES_VERSION} elasticsearch && \
    chown -R elasticsearch elasticsearch-${ES_VERSION}

# our entrypoint.sh sets and can override this
RUN sed -i '/-Xm[xs]/s/^/#/' /toolbox/elasticsearch/config/jvm.options

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    tar -xvf kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    rm -rf kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz && \
    ln -s kibana-${KIBANA_VERSION}-linux-x86_64 kibana && \
    chown -R elasticsearch kibana-${KIBANA_VERSION}-linux-x86_64

RUN cd /toolbox && git clone https://github.com/bitsofinfo/elasticsearch-gmail.git
RUN cd /toolbox && git clone https://github.com/bitsofinfo/csv2es.git

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#CMD ["python","/toolbox/elasticsearch-gmail/src/index_emails.py"]
