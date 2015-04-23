<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
  <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
  <xsl:template match="DescribeImageAttributeResponse">
    <xsl:element name="DescribeImageAttributeResponse" namespace="{$ns}">
      <xsl:element name="ResponseMetadata" namespace="{$ns}">
        <xsl:element name="RequestId" namespace="{$ns}">
          <xsl:value-of select="requestId"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="DescribeImageAttributeResult" namespace="{$ns}">
        <xsl:element name="ImageAttribute" namespace="{$ns}">
          <xsl:element name="ImageId" namespace="{$ns}">
            <xsl:value-of select="imageId"/>
          </xsl:element>
          <xsl:apply-templates select="launchPermission"/>
          <xsl:apply-templates select="productCodes"/>
          <xsl:apply-templates select="kernel"/>
          <xsl:apply-templates select="ramdisk"/>
          <xsl:apply-templates select="description"/>
          <xsl:apply-templates select="blockDeviceMapping"/>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="launchPermission">
    <xsl:for-each select="item">
      <xsl:element name="LaunchPermission" namespace="{$ns}">
        <xsl:element name="UserId" namespace="{$ns}">
          <xsl:value-of select="userId"/>
        </xsl:element>
        <xsl:element name="GroupName" namespace="{$ns}">
          <xsl:value-of select="group"/>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="productCodes">
    <xsl:for-each select="item">
      <xsl:element name="ProductCode" namespace="{$ns}">
        <xsl:value-of select="productCode"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="kernel">
    <xsl:element name="KernelId" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="ramdisk">
    <xsl:element name="RamdiskId" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="description">
    <xsl:element name="Description" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="blockDeviceMapping">
    <xsl:for-each select="item">
      <xsl:element name="BlockDeviceMapping" namespace="{$ns}">
        <xsl:element name="DeviceName" namespace="{$ns}">
          <xsl:value-of select="deviceName"/>
        </xsl:element>
        <xsl:element name="VirtualName" namespace="{$ns}">
          <xsl:value-of select="virtualName"/>
        </xsl:element>
        <xsl:apply-templates select="ebs"/>
        <xsl:apply-templates select="noDevice"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="ebs">
    <xsl:element name="Ebs" namespace="{$ns}">
      <xsl:element name="SnapshotId" namespace="{$ns}">
        <xsl:value-of select="snapshotId"/>
      </xsl:element>
      <!-- if a snapshot is specified, the volumeSize is optional -->
      <xsl:if test="volumeSize">
        <xsl:element name="VolumeSize" namespace="{$ns}">
          <xsl:value-of select="volumeSize"/>
        </xsl:element>
      </xsl:if>
      <xsl:element name="DeleteOnTermination" namespace="{$ns}">
        <xsl:if test="string-length(deleteOnTermination) = 0">
          <xsl:text>false</xsl:text>
        </xsl:if>
        <xsl:if test="string-length(deleteOnTermination) > 0">
          <xsl:value-of select="deleteOnTermination"/>
        </xsl:if>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="noDevice">
    <xsl:element name="NoDevice" namespace="{$ns}">
      <xsl:value-of select="'true'"/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
