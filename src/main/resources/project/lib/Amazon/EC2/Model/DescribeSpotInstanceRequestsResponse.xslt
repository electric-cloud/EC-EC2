<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
  exclude-result-prefixes="ec2">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
  <xsl:variable name="ns"
    select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
  <xsl:template match="DescribeSpotInstanceRequestsResponse">
    <xsl:element name="DescribeSpotInstanceRequestsResponse" namespace="{$ns}">
      <xsl:element name="ResponseMetadata" namespace="{$ns}">
        <xsl:element name="RequestId" namespace="{$ns}">
          <xsl:value-of select="requestId" />
        </xsl:element>
      </xsl:element>
      <xsl:element name="DescribeSpotInstanceRequestsResult" namespace="{$ns}">
        <xsl:apply-templates select="spotInstanceRequestSet"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="spotInstanceRequestSet">
    <xsl:for-each select="item">
      <xsl:element name="SpotInstanceRequest" namespace="{$ns}">
        <xsl:element name="SpotInstanceRequestId" namespace="{$ns}">
          <xsl:value-of select="spotInstanceRequestId"/>
        </xsl:element>
        <xsl:element name="SpotPrice" namespace="{$ns}">
          <xsl:value-of select="spotPrice"/>
        </xsl:element>
        <xsl:element name="Type" namespace="{$ns}">
          <xsl:value-of select="type"/>
        </xsl:element>
        <xsl:element name="State" namespace="{$ns}">
          <xsl:value-of select="state"/>
        </xsl:element>
        <xsl:apply-templates select="fault"/>
        <xsl:element name="ValidFrom" namespace="{$ns}">
          <xsl:value-of select="validFrom"/>
        </xsl:element>
        <xsl:element name="ValidUntil" namespace="{$ns}">
          <xsl:value-of select="validUntil"/>
        </xsl:element>
        <xsl:element name="LaunchGroup" namespace="{$ns}">
          <xsl:value-of select="launchGroup"/>
        </xsl:element>
        <xsl:element name="AvailabilityZoneGroup" namespace="{$ns}">
          <xsl:value-of select="availabilityZoneGroup"/>
        </xsl:element>
        <xsl:apply-templates select="launchSpecification"/>
        <xsl:element name="InstanceId" namespace="{$ns}">
          <xsl:value-of select="instanceId"/>
        </xsl:element>
        <xsl:element name="CreateTime" namespace="{$ns}">
          <xsl:value-of select="createTime"/>
        </xsl:element>
        <xsl:element name="ProductDescription" namespace="{$ns}">
          <xsl:value-of select="productDescription"/>
        </xsl:element>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="fault">
    <xsl:element name="Fault" namespace="{$ns}">
      <xsl:element name="Code" namespace="{$ns}">
        <xsl:value-of select="code" />
      </xsl:element>
      <xsl:element name="Message" namespace="{$ns}">
        <xsl:value-of select="message" />
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="launchSpecification">
    <xsl:element name="LaunchSpecification" namespace="{$ns}">
      <xsl:element name="ImageId" namespace="{$ns}">
        <xsl:value-of select="imageId"/>
      </xsl:element>
      <xsl:element name="KeyName" namespace="{$ns}">
        <xsl:value-of select="keyName"/>
      </xsl:element>
      <xsl:apply-templates select="groupSet"/>
      <xsl:element name="AddressingType" namespace="{$ns}">
        <xsl:value-of select="addressingType"/>
      </xsl:element>
      <xsl:element name="InstanceType" namespace="{$ns}">
        <xsl:value-of select="instanceType"/>
      </xsl:element>
      <xsl:element name="Placement" namespace="{$ns}">
        <xsl:element name="AvailabilityZone" namespace="{$ns}">
          <xsl:value-of select="placement/availabilityZone"/>
        </xsl:element>
        <xsl:element name="GroupName" namespace="{$ns}">
          <xsl:value-of select="placement/groupName"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="KernelId" namespace="{$ns}">
        <xsl:value-of select="kernelId"/>
      </xsl:element>
      <xsl:element name="RamdiskId" namespace="{$ns}">
        <xsl:value-of select="ramdiskId"/>
      </xsl:element>
      <xsl:apply-templates select="blockDeviceMapping"/>
      <xsl:element name="Monitoring" namespace="{$ns}">
        <xsl:element name="Enabled" namespace="{$ns}">
          <xsl:value-of select="monitoring/enabled"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="SubnetId" namespace="{$ns}">
        <xsl:value-of select="subnetId"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  <xsl:template match="groupSet">
    <xsl:for-each select="item">
      <xsl:element name="SecurityGroup" namespace="{$ns}">
        <xsl:value-of select="groupId"/>
      </xsl:element>
    </xsl:for-each>
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
