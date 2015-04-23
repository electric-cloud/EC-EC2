<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
  <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
  <xsl:template match="DescribeVolumesResponse">
    <xsl:element name="DescribeVolumesResponse" namespace="{$ns}">
      <xsl:element name="ResponseMetadata" namespace="{$ns}">
        <xsl:element name="RequestId" namespace="{$ns}">
          <xsl:value-of select="requestId"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="DescribeVolumesResult" namespace="{$ns}">
        <xsl:apply-templates select="volumeSet"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="volumeSet">
    <xsl:for-each select="item">
      <xsl:element name="Volume" namespace="{$ns}">
        <xsl:element name="VolumeId" namespace="{$ns}">
          <xsl:value-of select="volumeId"/>
        </xsl:element>
        <xsl:element name="Size" namespace="{$ns}">
          <xsl:value-of select="size"/>
        </xsl:element>
        <xsl:element name="SnapshotId" namespace="{$ns}">
          <xsl:value-of select="snapshotId"/>
        </xsl:element>
        <xsl:element name="AvailabilityZone" namespace="{$ns}">
          <xsl:value-of select="availabilityZone"/>
        </xsl:element>
        <xsl:element name="Status" namespace="{$ns}">
          <xsl:value-of select="status"/>
        </xsl:element>
        <xsl:element name="CreateTime" namespace="{$ns}">
          <xsl:value-of select="createTime"/>
        </xsl:element>
        <xsl:apply-templates select="attachmentSet"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="attachmentSet">
    <xsl:for-each select="item">
      <xsl:element name="Attachment" namespace="{$ns}">
        <xsl:element name="VolumeId" namespace="{$ns}">
          <xsl:value-of select="volumeId"/>
        </xsl:element>
        <xsl:element name="InstanceId" namespace="{$ns}">
          <xsl:value-of select="instanceId"/>
        </xsl:element>
        <xsl:element name="Device" namespace="{$ns}">
          <xsl:value-of select="device"/>
        </xsl:element>
        <xsl:element name="Status" namespace="{$ns}">
          <xsl:value-of select="status"/>
        </xsl:element>
        <xsl:element name="AttachTime" namespace="{$ns}">
          <xsl:value-of select="attachTime"/>
        </xsl:element>
        <xsl:element name="DeleteOnTermination" namespace="{$ns}">
          <xsl:if test="string-length(deleteOnTermination) = 0">false</xsl:if>
          <xsl:if test="string-length(deleteOnTermination) > 0">
            <xsl:value-of select="deleteOnTermination"/>
          </xsl:if>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
