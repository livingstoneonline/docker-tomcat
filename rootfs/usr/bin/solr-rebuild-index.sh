#!/bin/bash

LIB=/opt/tomcat/webapps/fedoragsearch/WEB-INF/lib
JARS=$LIB/log4j-1.2.15.jar:$LIB/activation-1.1.1.jar:$LIB/axis.jar:$LIB/commons-discovery.jar:$LIB/commons-logging.jar:$LIB/jaxrpc-api-1.1.jar:$LIB/mail.jar:$LIB/saaj-api-1.3.jar:$LIB/lucene-core-2.4.0.jar:$LIB/wsdl4j-1.5.1.jar:$LIB/PDFBox-0.7.2.jar:$LIB/xml-apis.jar

java -Xms64m -Xmx256m \
      -Dfedoragsearch.fgsUserName=${FEDORA_ADMIN_USER} \
      -Dfedoragsearch.fgsPassword=${FEDORA_ADMIN_PASSWORD} \
      -cp "/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes:${JARS}" \
      dk.defxws.fedoragsearch.client.RESTClient \
      localhost:8080 updateIndex fromFoxmlFiles
