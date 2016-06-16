FROM livingstoneonline/mysql
MAINTAINER Nigel Banks <nigel.g.banks@gmail.com>

LABEL "License"="GPLv3" \
      "Version"="0.0.1"

EXPOSE 8080

COPY build /build

# Install Java / Tomcat.
ARG TOMCAT_VERSION="7.0.69"

ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle \
    CATALINA_HOME=/opt/tomcat \
    CATALINA_BASE=/opt/tomcat \
    KAKADU_HOME=/opt/adore-djatoka/bin/Linux-x86-64 \
    SOLR_HOME=/opt/solr

RUN addgroup --gid 110 tomcat && \
    adduser --system --disabled-password --no-create-home --ingroup tomcat --uid 105 --shell /sbin/nologin --home /opt/tomcat tomcat && \
    apt-get update && \
    add-apt-repository -y ppa:webupd8team/java && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install maven oracle-java8-installer oracle-java8-set-default && \
    update-java-alternatives -s java-8-oracle && \
    curl -L http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION%%.*}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | \
    tar -xzf - -C /tmp && \
    mv /tmp/apache-tomcat-${TOMCAT_VERSION} ${CATALINA_HOME} && \
    rm -rf ${CATALINA_HOME}/webapps/docs && \
    rm -rf ${CATALINA_HOME}/webapps/examples && \
    ln -s /opt/adore-djatoka/bin/Linux-x86-64/kdu_compress /usr/bin/kdu_compress && \
    ln -s /opt/adore-djatoka/bin/Linux-x86-64/kdu_expand /usr/bin/kdu_expand && \
    ln -s /opt/adore-djatoka/lib/Linux-x86-64/libkdu_a60R.so /usr/lib/libkdu_a60R.so && \
    ln -s /opt/adore-djatoka/lib/Linux-x86-64/libkdu_jni.so /usr/lib/libkdu_jni.so && \
    ln -s /opt/adore-djatoka/lib/Linux-x86-64/libkdu_v60R.so /usr/lib/libkdu_v60R.so && \
    cleanup

# Install Fedora.
ARG FEDORA_VERSION="3.8.1"

ENV FEDORA_HOME=/opt/fedora
RUN mysql_install_db --datadir="/var/lib/mysql" --user=mysql && \
    sleep 15 && \
    { mysqld_safe & } && \
    sleep 10 && \
    mysql -e "CREATE DATABASE fedora3;" && \
    mysql -e "CREATE USER 'fedoraAdmin'@'localhost' IDENTIFIED BY 'fedoraAdmin';" && \
    mysql -e "GRANT ALL ON fedora3.* TO fedoraAdmin@'%' IDENTIFIED BY 'fedoraAdmin';" && \
    mkdir ${FEDORA_HOME} && \
    curl -L -o /tmp/fcrepo-installer-${FEDORA_VERSION}.jar \
    http://sourceforge.net/projects/fedora-commons/files/fedora/${FEDORA_VERSION}/fcrepo-installer-${FEDORA_VERSION}.jar/download && \
    java -jar /tmp/fcrepo-installer-${FEDORA_VERSION}.jar /build/install.properties && \
    ${CATALINA_HOME}/bin/catalina.sh start && sleep 90 && \
    ${CATALINA_HOME}/bin/catalina.sh stop && sleep 30 && \
    mysqldump -u fedoraAdmin --password=fedoraAdmin fedora3 | gzip -c > /run/fedora3.sql.gz && \
    rm -fr ${FEDORA_HOME}/data/fedora-xacml-policies/repository-policies/default && \
    mysqladmin shutdown && sleep 30 && \
    curl -L -o ${CATALINA_HOME}/webapps/fedora/WEB-INF/lib/fcrepo-drupalauthfilter-3.8.1.jar \
    https://github.com/Islandora/islandora_drupal_filter/releases/download/v7.1.3/fcrepo-drupalauthfilter-3.8.1.jar && \
    chown -R tomcat:tomcat ${FEDORA_HOME} && \
    rm -rf ${FEDORA_HOME}/data/fedora-xacml-policies/repository-policies/default/* && \
    rm -rf ${FEDORA_HOME}/docs && \
    rm -rf ${CATALINA_HOME}/webapps/*.war && \
    rm -rf ${CATALINA_HOME}/webapps/fedora-demo && \
    rm -rf ${CATALINA_HOME}/logs/* && \
    rm -rf ${FEDORA_HOME}/server/logs/* && \
    rm -rf /var/lib/mysql/* && \
    cleanup

# Configuration Settings.
ENV JAVA_OPTS="" \
    CATALINA_OPTS="-server -XX:+CMSClassUnloadingEnabled -Djava.awt.headless=true -Djava.security.egd=file:/dev/urandom -Dkakadu.home=/opt/adore-djatoka/bin/Linux-x86-64 -DLD_LIBRARY_PATH=/opt/adore-djatoka/lib/Linux-x86-64 -Djava.library.path=/opt/adore-djatoka/lib/Linux-x86-64" \
    TOMCAT_ADMIN_USER=admin \
    TOMCAT_ADMIN_PASSWORD=tomcat \
    FEDORA_DB_NAME=fedora3 \
    FEDORA_DB_USER=fedoraAdmin \
    FEDORA_DB_PASSWORD=fedoraAdmin \
    FEDORA_ADMIN_USER=fedoraAdmin \
    FEDORA_ADMIN_PASSWORD=fedoraAdmin \
    FEDORA_INTERNAL_PASSWORD=password \
    FEDORA_IMPORT_DATA=no \
    FEDORA_REBUILD=no

RUN rm -rf ${FEDORA_HOME}/data/activemq-data/localhost/KahaDB/* \
           ${FEDORA_HOME}/data/resourceIndex/xaStatementStore/* \
           ${FEDORA_HOME}/data/resourceIndex/xaStringPool/*

# Adore-Djatoka and Solr are installed by this copy.
COPY rootfs /
