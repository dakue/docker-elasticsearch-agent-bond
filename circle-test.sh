#!/bin/bash
set -e

ES_VERSIONS="1.7 2.0 2.1 2.2"

echo "$(date --rfc-3339=seconds) INFO: starting to test"
for VERSION in $ES_VERSIONS
do
    VERSION_NAME="es-$(echo $VERSION | sed 's|\.|-|g')"
    echo "INFO: starting Elasticsearch version $VERSION"
    docker run -d -p 9200:9200 -p 8778:8778 -p 9779:9779 --name $VERSION_NAME dakue/elasticsearch-agent-bond:$VERSION
    echo "INFO: waiting for Elasticsearch to be available"
    ( i=0; until nc -w 1 -q 0 localhost 9200; do echo $i; test $i -ge 5 && break; sleep 5; ((i++)); done ) || exit 0
    echo "INFO: $VERSION Elasticsearch output"
    curl http://localhost:9200
    echo "INFO: $VERSION Jolokia output"
    curl http://localhost:8778/jolokia/version
    echo "INFO: $VERSION JMX exporter output"
    curl http://localhost:9779/metrics | grep -v -E "HELP|TYPE"
    echo "INFO: stopping Elasticsearch"
    docker stop $VERSION_NAME
done
echo "$(date --rfc-339=seconds) INFO: tests finished"
