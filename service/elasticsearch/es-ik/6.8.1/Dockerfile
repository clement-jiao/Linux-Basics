# docker build . -t registry-harbor.clement.com/clement/es-ik:6.8.1
# docker login registry-harbor.clement.com
# docker push registry-harbor.clement.com/clement/es-ik:6.8.1
# elasticsearch:6.8.1 + ik-6.8.1

# https://github.com/elastic/elasticsearch-docker
FROM harbor.ibaiqiu.com/docker.io/library/elasticsearch:6.8.1

# https://github.com/medcl/elasticsearch-analysis-ik/releases
ENV IK_RELEASE=https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.8.1/elasticsearch-analysis-ik-6.8.1.zip
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch $IK_RELEASE
