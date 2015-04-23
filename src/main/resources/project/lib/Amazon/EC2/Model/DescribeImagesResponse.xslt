<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
  <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
  <xsl:template match="DescribeImagesResponse">
    <xsl:element name="DescribeImagesResponse" namespace="{$ns}">
      <xsl:element name="ResponseMetadata" namespace="{$ns}">
        <xsl:element name="RequestId" namespace="{$ns}">
          <xsl:value-of select="requestId"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="DescribeImagesResult" namespace="{$ns}">
        <xsl:apply-templates select="imagesSet"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="imagesSet">
    <xsl:for-each select="item">
      <xsl:element name="Image" namespace="{$ns}">
        <xsl:element name="ImageId" namespace="{$ns}">
          <xsl:value-of select="imageId"/>
        </xsl:element>
        <xsl:element name="ImageLocation" namespace="{$ns}">
          <xsl:value-of select="imageLocation"/>
        </xsl:element>
        <xsl:element name="ImageState" namespace="{$ns}">
          <xsl:value-of select="imageState"/>
        </xsl:element>
        <xsl:element name="OwnerId" namespace="{$ns}">
          <xsl:value-of select="imageOwnerId"/>
        </xsl:element>
        <xsl:element name="Visibility" namespace="{$ns}">
          <xsl:if test="isPublic = 'true'">
            <xsl:text>Public</xsl:text>
          </xsl:if>
          <xsl:if test="not(isPublic = 'true')">
            <xsl:text>Private</xsl:text>
          </xsl:if>
        </xsl:element>
        <xsl:apply-templates select="productCodes"/>
        <xsl:element name="Architecture" namespace="{$ns}">
          <xsl:value-of select="architecture"/>
        </xsl:element>
        <xsl:element name="ImageType" namespace="{$ns}">
          <xsl:value-of select="imageType"/>
        </xsl:element>
        <xsl:element name="KernelId" namespace="{$ns}">
          <xsl:value-of select="kernelId"/>
        </xsl:element>
        <xsl:element name="RamdiskId" namespace="{$ns}">
          <xsl:value-of select="ramdiskId"/>
        </xsl:element>
        <xsl:element name="Platform" namespace="{$ns}">
          <xsl:value-of select="platform"/>
        </xsl:element>
        <xsl:apply-templates select="stateReason"/>
        <xsl:element name="ImageOwnerAlias" namespace="{$ns}">
          <xsl:value-of select="imageOwnerAlias"/>
        </xsl:element>
        <xsl:element name="Name" namespace="{$ns}">
          <xsl:value-of select="name"/>
        </xsl:element>
        <xsl:element name="Description" namespace="{$ns}">
          <xsl:value-of select="description"/>
        </xsl:element>
        <xsl:element name="RootDeviceType" namespace="{$ns}">
          <xsl:value-of select="rootDeviceType"/>
        </xsl:element>
        <xsl:element name="RootDeviceName" namespace="{$ns}">
          <xsl:value-of select="rootDeviceName"/>
        </xsl:element>
        <xsl:apply-templates select="blockDeviceMapping"/>
        <xsl:element name="VirtualizationType" namespace="{$ns}">
          <xsl:value-of select="virtualizationType"/>
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
  <xsl:template match="stateReason">
    <xsl:element name="StateReason" namespace="{$ns}">
      <xsl:element name="Code" namespace="{$ns}">
        <xsl:value-of select="code"/>
      </xsl:element>
      <xsl:element name="Message" namespace="{$ns}">
        <xsl:value-of select="message"/>
      </xsl:element>
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
