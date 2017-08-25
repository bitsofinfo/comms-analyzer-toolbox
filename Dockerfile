FROM centos:latest

EXPOSE 5601

RUN yum -y install epel-release && yum clean all
RUN yum -y install zip unzip curl git java-1.8.0-openjdk python python-pip && yum clean all

RUN pip install beautifulsoup4
RUN pip install tornado

RUN mkdir /toolbox

ADD kibana.yml /toolbox
RUN useradd -r elasticsearch

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.zip && \
    unzip elasticsearch-5.5.2.zip && \
    rm -rf elasticsearch-5.5.2.zip && \
    chown -R elasticsearch elasticsearch-5.5.2

RUN cd /toolbox && \
    curl -O https://artifacts.elastic.co/downloads/kibana/kibana-5.5.2-linux-x86_64.tar.gz && \
    tar -xvf kibana-5.5.2-linux-x86_64.tar.gz && \
    rm -rf kibana-5.5.2-linux-x86_64.tar.gz && \
    chown -R elasticsearch kibana-5.5.2-linux-x86_64

RUN cd /toolbox && git clone https://github.com/bitsofinfo/elasticsearch-gmail.git

ADD entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#CMD ["python","/toolbox/elasticsearch-gmail/src/index_emails.py"]
