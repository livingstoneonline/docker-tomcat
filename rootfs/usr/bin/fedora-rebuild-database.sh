#!/usr/bin/expect -f
set timeout 100
spawn java -server -Xmn64m -Xms256m -Xmx256m \
      -cp "/opt/tomcat/webapps/fedora/WEB-INF/classes:/opt/fedora/server/bin:/opt/tomcat/webapps/fedora/WEB-INF/lib/*" \
      -Djava.endorsed.dirs=/opt/tomcat/common/endorsed:/opt/tomcat/common/lib \
      -Djavax.net.ssl.trustStore=/opt/fedora/server/truststore \
      -Djavax.net.ssl.trustStorePassword=tomcat \
      -Djavax.xml.parsers.DocumentBuilderFactory=org.apache.xerces.jaxp.DocumentBuilderFactoryImpl \
      -Djavax.xml.parsers.SAXParserFactory=org.apache.xerces.jaxp.SAXParserFactoryImpl \
      -Dcom.sun.xacml.PolicySchema=/opt/fedora/server/xsd/cs-xacml-schema-policy-01.xsd \
      -Dfedora.home=/opt/fedora \
      -Dfedora.web.inf.lib=/opt/tomcat/webapps/fedora/WEB-INF/lib \
      org.fcrepo.server.utilities.rebuild.Rebuild

expect "Enter (1-3) -->"
send "2\r"
expect "Enter (1-2) -->"
send "1\r"
expect eof
puts "exited"
