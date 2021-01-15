FROM centos:latest

EXPOSE 9200
EXPOSE 5601

ENV ES_VERSION 7.2.0
ENV KIBANA_VERSION 7.2.0

RUN yum -y install epel-release && yum clean all
RUN yum -y install unzip zip curl git java-1.8.0-openjdk python38 python38-pip && yum clean all

RUN pip3 install --upgrade pip
RUN pip3 install beautifulsoup4 python-dateutil html5lib lxml tornado retrying pyelasticsearch joblib click

RUN mkdir /toolbox
ADD kibana.yml /toolbox
#Trick to adjust access rights between host and docker shared directories
RUN groupadd  -g 1001 elasticsearch 
RUN useradd -r elasticsearch --uid 1000 --gid 1001

RUN cd /toolbox && \
#Elasticsearch is now a tar.gz file
    curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz && \
    tar -xvzf elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz && \
    rm -rf elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz && \
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
#get this intersting repo too
RUN cd /toolbox && git clone https://github.com/cvandeplas/ELK-forensics

#Trick to modify elasticsearch-gmail.git repo to comply to new elastic search requirements
RUN sed -i 's~request = HTTPRequest(tornado.options.options.es_url + "/_bulk", method="POST", body=upload_data_txt, request_timeout=tornado.options.options.es_http_timeout_seconds)~request = HTTPRequest(tornado.options.options.es_url + "/_bulk", method="POST", body=upload_data_txt, request_timeout=tornado.options.options.es_http_timeout_seconds,headers={"content-type":"application/json"})~g' /toolbox/elasticsearch-gmail/src/index_emails.py
#New elasticsearch mandatory params
RUN sed -i 's/#node.name: node-1/node.name: node-1/g' /toolbox/elasticsearch/config/elasticsearch.yml
RUN sed -i 's/#cluster.initial_master_nodes: \["node-1", "node-2"\]/cluster.initial_master_nodes: \["node-1"\]/g' /toolbox/elasticsearch/config/elasticsearch.yml



ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
