<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
  <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
  <xsl:template match="DescribeInstanceAttributeResponse">
    <xsl:element name="DescribeInstanceAttributeResponse" namespace="{$ns}">
      <xsl:element name="ResponseMetadata" namespace="{$ns}">
        <xsl:element name="RequestId" namespace="{$ns}">
          <xsl:value-of select="requestId"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="DescribeInstanceAttributeResult" namespace="{$ns}">
        <xsl:element name="InstanceAttribute" namespace="{$ns}">
          <xsl:element name="InstanceId" namespace="{$ns}">
            <xsl:value-of select="instanceId"/>
          </xsl:element>
          <xsl:apply-templates select="instanceType"/>
          <xsl:apply-templates select="kernel"/>
          <xsl:apply-templates select="ramdisk"/>
          <xsl:apply-templates select="userData"/>
          <xsl:apply-templates select="disableApiTermination"/>
          <xsl:apply-templates select="instanceInitiatedShutdownBehavior"/>
          <xsl:apply-templates select="rootDeviceName"/>
          <xsl:apply-templates select="blockDeviceMapping"/>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="instanceType">
    <xsl:element name="InstanceType" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
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
  <xsl:template match="userData">
    <xsl:element name="UserData" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="disableApiTermination">
    <xsl:element name="DisableApiTermination" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="instanceInitiatedShutdownBehavior">
    <xsl:element name="InstanceInitiatedShutdownBehavior" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="rootDeviceName">
    <xsl:element name="RootDeviceName" namespace="{$ns}">
      <xsl:value-of select="value"/>
    </xsl:element>
  </xsl:template>
  <xsl:template match="blockDeviceMapping">
    <xsl:for-each select="item">
      <xsl:element name="BlockDeviceMapping" namespace="{$ns}">
        <xsl:element name="DeviceName" namespace="{$ns}">
          <xsl:value-of select="deviceName"/>
        </xsl:element>
        <xsl:apply-templates select="ebs"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="ebs">
    <xsl:element name="Ebs" namespace="{$ns}">
      <xsl:element name="VolumeId" namespace="{$ns}">
        <xsl:value-of select="volumeId"/>
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
  </xsl:template>
</xsl:stylesheet>
