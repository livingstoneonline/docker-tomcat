<?xml version="1.0" encoding="UTF-8"?>
<!-- We need all lower level namespaces to be declared here for exclude-result-prefixes attributes
  to be effective -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
  xmlns:rel="info:fedora/fedora-system:def/relations-external#"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:fedora-model="info:fedora/fedora-system:def/model#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:sparql="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:res="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:xalan="http://xml.apache.org/xalan"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
  xmlns:islandora-exts="xalan://ca.upei.roblib.DataStreamForXSLT"
  xmlns:encoder="xalan://java.net.URLEncoder"
  xmlns:java="http://xml.apache.org/xalan/java"
  exclude-result-prefixes="exts">
  
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <xsl:param name="REPOSITORYNAME" select="repositoryName"/>
  <xsl:param name="FEDORASOAP" select="repositoryName"/>
  <xsl:param name="FEDORAUSER" select="repositoryName"/>
  <xsl:param name="FEDORAPASS" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPATH" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPASS" select="repositoryName"/>
  
  <xsl:variable name="PROT">http</xsl:variable>
  <xsl:variable name="HOST">localhost</xsl:variable>
  <xsl:variable name="PORT">8080</xsl:variable>
  <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
  <!--  Used for indexing other objects. -->
  <xsl:variable name="FEDORA" xmlns:java_string="xalan://java.lang.String" select="substring($FEDORASOAP, 1, java_string:lastIndexOf(java_string:new(string($FEDORASOAP)), '/'))"/>
  
  <!-- FOXML Properties -->
  <!--  Used for indexing other objects. -->
  <xsl:include href="/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/traverse-graph.xslt"/>
  <xsl:include href="/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/FOXML_properties_to_solr.xslt"/>
  <xsl:include href="/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/datastream_info_to_solr.xslt"/>
  <xsl:include href="/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/RELS-EXT_to_solr.xslt"/>
  <xsl:include href="/opt/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/RELS-INT_to_solr.xslt"/>
  
  <!-- Decide which objects to modify the index of -->
  <xsl:template match="/">
    <update>
      <!-- The following allows only active and data oriented FedoraObjects to be indexed -->
      <xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP' or @ID='DS-COMPOSITE-MODEL'])">
        <xsl:choose>
          <xsl:when test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
            <add>
              <xsl:apply-templates select="/foxml:digitalObject" mode="indexFedoraObject">
                <xsl:with-param name="PID" select="$PID"/>
              </xsl:apply-templates>
            </add>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="/foxml:digitalObject" mode="unindexFedoraObject"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </update>
  </xsl:template>
  
  <!-- Index an object -->
  <xsl:template match="/foxml:digitalObject" mode="indexFedoraObject">
    <xsl:param name="PID"/>
    <doc>
      
      <field name="PID">
        <xsl:value-of select="$PID"/>
      </field>
      
      <xsl:apply-templates select="foxml:objectProperties/foxml:property"/>
      <xsl:apply-templates select="/foxml:digitalObject" mode="index_object_datastreams"/>
      
      <xsl:variable name="graph">
        <xsl:call-template name="_traverse_graph">
          <xsl:with-param name="risearch" select="concat($FEDORA, '/risearch')"/>
          <xsl:with-param name="to_traverse_in">
            <sparql:result>
              <sparql:obj>
                <xsl:attribute name="uri">info:fedora/<xsl:value-of select="$PID"/></xsl:attribute>
              </sparql:obj>
            </sparql:result>
          </xsl:with-param>
          <xsl:with-param name="query">
            PREFIX fre: &lt;info:fedora/fedora-system:def/relations-external#&gt;
            PREFIX fm: &lt;info:fedora/fedora-system:def/model#&gt;
            PREFIX fm: &lt;info:fedora/fedora-system:def/model#&gt;
            PREFIX fv: &lt;info:fedora/fedora-system:def/view#&gt;
            PREFIX islandora: &lt;http://islandora.ca/ontology/relsext#&gt;
            SELECT ?obj FROM &lt;#ri&gt; WHERE {
              ?obj islandora:isPageOf &lt;%PID_URI%&gt; .
            }
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="pages" select="xalan:nodeset($graph)//sparql:obj[@uri != concat('info:fedora/', $PID)]"/>
      
      <xsl:for-each select="$pages">
        <xsl:call-template name="field">
          <xsl:with-param name="name">pages_ms</xsl:with-param>
          <xsl:with-param name="value" select="substring-after(@uri, '/')"/>
        </xsl:call-template>
      </xsl:for-each>
      
      <xsl:choose>
        <xsl:when test="count($pages) >= 1">
          <field name="viewable_b">true</field>
        </xsl:when>
        <xsl:otherwise>
          <field name="viewable_b">false</field>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test="foxml:datastream[@ID = 'ZIP']">
          <field name="downloadable_b">true</field>
        </xsl:when>
        <xsl:otherwise>
          <field name="downloadable_b">false</field>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:variable name="xml_url" select="concat(substring-before($FEDORA, '://'), '://', encoder:encode($FEDORAUSER), ':', encoder:encode($FEDORAPASS), '@', substring-after($FEDORA, '://') , '/objects/', substring-after($pages[1]/@uri, '/'), '/objectXML')"/>
      <xsl:variable name="object" select="document($xml_url)"/>
      <xsl:if test="$object">
        <xsl:choose>
          <xsl:when test="$object/foxml:digitalObject/foxml:datastream[@ID = 'POLICY']">
            <field name="hidden_b">true</field>
          </xsl:when>
          <xsl:otherwise>
            <field name="hidden_b">false</field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      
      <xsl:for-each select="foxml:datastream[@ID = 'MODS' or @ID = 'TEI' or @ID = 'RELS-EXT']">
        <xsl:choose>
          <xsl:when test="@CONTROL_GROUP='X'">
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="foxml:datastreamVersion[last()]/foxml:xmlContent"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="@CONTROL_GROUP='M' and foxml:datastreamVersion[last()][@MIMETYPE='text/xml' or @MIMETYPE='application/xml' or @MIMETYPE='application/rdf+xml' or @MIMETYPE='text/html' or @MIMETYPE='chemical/x-cml']">
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="document(concat($PROT, '://', encoder:encode($FEDORAUSER), ':', encoder:encode($FEDORAPASS), '@', $HOST, ':', $PORT, '/fedora/objects/', $PID, '/datastreams/', @ID, '/content'))"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="@CONTROL_GROUP='M' and foxml:datastreamVersion[last() and not(starts-with(@MIMETYPE, 'image') or starts-with(@MIMETYPE, 'audio') or starts-with(@MIMETYPE, 'video') or @MIMETYPE = 'application/pdf')]">
            <xsl:apply-templates select="foxml:datastreamVersion[last()]">
              <xsl:with-param name="content" select="java:ca.discoverygarden.gsearch_extensions.XMLStringUtils.escapeForXML(normalize-space(exts:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)))"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </doc>
  </xsl:template>
  
  <!-- Delete the solr doc of an object -->
  <xsl:template match="/foxml:digitalObject" mode="unindexFedoraObject">
    <xsl:comment> name="PID" This is a hack, because the code requires that to be present </xsl:comment>
    <delete>
      <id>
        <xsl:value-of select="$PID"/>
      </id>
    </delete>
  </xsl:template>
  
  <!-- MODS -->
  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]">
    <xsl:param name="content"/>
    <field name="mods">
      <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
      <xsl:copy-of select="$content"/>
      <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </field>
    
    <xsl:for-each select="$content//mods:mods[1]">
      <xsl:apply-templates select="mods:*"/>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">title_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:titleInfo/mods:title[not(@*)]"/>
      </xsl:call-template>
      
      <xsl:for-each select="mods:originInfo/mods:dateCreated[not(@*)]">
        <xsl:sort select="text()"/>
        <xsl:call-template name="field">
          <xsl:with-param name="name">date_ms</xsl:with-param>
          <xsl:with-param name="value" select="text()"></xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
      
      <field name="creator_s">
        <xsl:variable name="creator_text">
          <xsl:for-each select="mods:name[mods:role/mods:roleTerm[@type='text']/text() = 'creator']">
            <xsl:sort select="mods:namePart/text()"/>
            <xsl:value-of select="mods:namePart/text()"/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
          <xsl:if test="mods:note[@displayLabel='creator']">
            <xsl:value-of select="'Unknown creator'"/>
            <xsl:text>; </xsl:text>
          </xsl:if>
        </xsl:variable>
        <xsl:value-of select="substring($creator_text,0,string-length($creator_text)-1)"/>
      </field>
      
      <xsl:for-each select="mods:name[mods:role/mods:roleTerm[@type='text']/text() = 'creator']">
        <xsl:sort select="mods:namePart/text()"/>
        <field name="creator_ms">
          <xsl:value-of select="mods:namePart/text()"/>
        </field>
      </xsl:for-each>
      
      <xsl:if test="mods:note[@displayLabel='creator']">
        <field name="creator_ms">
          <xsl:value-of select="'Unknown creator'"/>
        </field>
      </xsl:if>
      
      <field name="addressee_s">
        <xsl:variable name="addressee_text">
          <xsl:for-each select="mods:name[mods:role/mods:roleTerm[@type='text']/text() = 'addressee']">
            <xsl:sort select="mods:namePart/text()"/>
            <xsl:value-of select="mods:namePart/text()"/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
          <xsl:if test="mods:note[@displayLabel='addressee']">
            <xsl:value-of select="'Unknown addressee'"/>
            <xsl:text>; </xsl:text>
          </xsl:if>
        </xsl:variable>
        <xsl:value-of select="substring($addressee_text,0,string-length($addressee_text)-1)"/>
      </field>
      
      <xsl:for-each select="mods:name[mods:role/mods:roleTerm[@type='text']/text() = 'addressee']">
        <xsl:sort select="mods:namePart/text()"/>
        <field name="addressee_ms">
          <xsl:value-of select="mods:namePart/text()"/>
        </field>
      </xsl:for-each>
      <xsl:if test="mods:note[@displayLabel='addressee']">
        <field name="addressee_ms">
          <xsl:value-of select="'Unknown addressee'"/>
        </field>
      </xsl:if>
      
      <xsl:for-each select="mods:name[mods:role/mods:roleTerm[@type='text']/text() = 'addressee']">
        <xsl:sort select="mods:namePart/text()"/>
        <field name="addressee_description_ms">
          <xsl:value-of select="mods:namePart/text()"/> : <xsl:value-of select="mods:description/text()"/>
        </field>
      </xsl:for-each>
      
      <xsl:if test="mods:note[@displayLabel='addressee']">
        <field name="addressee_description_ms">Unknown addressee : </field>
      </xsl:if>
      
      <xsl:if test="mods:originInfo[@displayLabel='Livingstone']/mods:place/mods:placeTerm[@type = 'text']">
        <field name="place_s">
          <xsl:value-of select="mods:originInfo[@displayLabel='Livingstone']/mods:place/mods:placeTerm[@type = 'text']"/>
        </field>
      </xsl:if>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">extent_pages_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:physicalDescription/mods:extent[@unit = 'pages']"/>
      </xsl:call-template>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">extent_size_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:physicalDescription/mods:extent[@unit = 'mm']"/>
      </xsl:call-template>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">catalog_identifier_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:identifier[@type='local' and @displayLabel='Canonical Catalog Number']"/>
      </xsl:call-template>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">master_id_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:identifier[@type='local' and @displayLabel='master_id']"/>
      </xsl:call-template>
      
      <xsl:call-template name="field">
        <xsl:with-param name="name">copy_identifier_s</xsl:with-param>
        <xsl:with-param name="value" select="mods:identifier[@type='local' and @displayLabel='NLS copy identifier'][1]"/>
      </xsl:call-template>
      
      <field name="repository_s">
        <xsl:variable name="repository_text">
          <xsl:for-each select="mods:relatedItem[@type='original' and mods:name/mods:role/mods:roleTerm[@type='text']/text() = 'repository']">
            <xsl:value-of select="mods:name/mods:namePart/text()"/>
            <xsl:if test="mods:location/mods:shelfLocator">
              <xsl:text>: </xsl:text>
              <xsl:value-of select="mods:location/mods:shelfLocator/text()"/>
            </xsl:if>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="substring($repository_text,0,string-length($repository_text)-1)"/>
      </field>
      
      <xsl:for-each select="mods:relatedItem[@type='original' and mods:name/mods:role/mods:roleTerm[@type='text']/text() = 'repository']">
        <field name="repository_ms">
          <xsl:value-of select="mods:name/mods:namePart/text()"/>
        </field>        
      </xsl:for-each>
      
      <field name="genre_s">
        <xsl:variable name="genre_text">
          <xsl:for-each select="mods:genre[@authority='aat']">
            <xsl:value-of select="text()"/>
            <xsl:text>; </xsl:text>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="substring($genre_text,0,string-length($genre_text)-1)"/>
      </field>
      
      <xsl:for-each select="mods:genre[@authority='aat']">
        <field name="genre_ms">
          <xsl:value-of select="text()"/>
        </field>
      </xsl:for-each>
      
      <field name="otherVersion_s">
        <xsl:for-each select="mods:relatedItem[@type='otherVersion']">
          <xsl:value-of select="mods:identifier/text()"/>
          <xsl:text> </xsl:text>
        </xsl:for-each>
      </field>
      
      <xsl:for-each select="mods:relatedItem[@type='otherVersion']">
        <field name="otherVersion_ms">
          <xsl:value-of select="mods:identifier/text()"/>
        </field>
      </xsl:for-each>
      
      <xsl:for-each select="mods:originInfo/mods:dateCreated[@encoding='iso8601']">
        <xsl:variable name="dateStart"
          select="java:edu.ucla.library.IsoToSolrDateConverter.getStartDateFromIsoDateString(normalize-space(text()))" />
        <xsl:variable name="dateEnd"
          select="java:edu.ucla.library.IsoToSolrDateConverter.getEndDateFromIsoDateString(normalize-space(text()))" />
        <xsl:variable name="counter" select="substring-before($dateStart,'-')" />
        <xsl:variable name="end" select="substring-before($dateEnd,'-')" />
        
        <xsl:call-template name="date-loop">
          <xsl:with-param name="counter">
            <xsl:number value="number($counter)" />
          </xsl:with-param>
          <xsl:with-param name="end">
            <xsl:number value="number($end)" />
          </xsl:with-param>
        </xsl:call-template>
        
        <field name="dateRangeStart_dt">
          <xsl:value-of select="$dateStart"/>
        </field>
        
        <field name="dateRangeEnd_dt">
          <xsl:value-of select="$dateEnd"/>
        </field>
      </xsl:for-each>
      
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="field">
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:if test="not(normalize-space($value) = '')">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:value-of select="$value"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="date-loop">
    <xsl:param name="counter"/>
    <xsl:param name="end"/>
    <xsl:if test="$counter &lt;= $end">
      <field name="dateRangeYear_mi">
        <xsl:value-of select="$counter"/>
      </field>
      <xsl:call-template name="date-loop">
        <xsl:with-param name="counter">
          <xsl:number value="number($counter)+1" />
        </xsl:with-param>
        <xsl:with-param name="end">
          <xsl:number value="$end" />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="text()"/>
  <xsl:template match="text()" mode="indexFedoraObject"/>
  <xsl:template match="text()" mode="unindexFedoraObject"/>
  <xsl:template match="text()" mode="index_object_datastreams"/>
</xsl:stylesheet>
