<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="DescribeSubnetsResponse">
		<xsl:element name="DescribeSubnetsResponse" namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="DescribeSubnetsResult" namespace="{$ns}">
				<xsl:apply-templates select="subnetSet" />
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match="subnetSet">
		<xsl:for-each select="item">
			<xsl:element name="Subnet" namespace="{$ns}">
				<xsl:element name="SubnetId" namespace="{$ns}">
					<xsl:value-of select="subnetId" />
				</xsl:element>
				<xsl:element name="SubnetState" namespace="{$ns}">
					<xsl:value-of select="state" />
				</xsl:element>
				<xsl:element name="VpcId" namespace="{$ns}">
					<xsl:value-of select="vpcId" />
				</xsl:element>
				<xsl:element name="CidrBlock" namespace="{$ns}">
					<xsl:value-of select="cidrBlock" />
				</xsl:element>
				<xsl:element name="AvailableIpAddressCount" namespace="{$ns}">
					<xsl:value-of select="availableIpAddressCount" />
				</xsl:element>
				<xsl:element name="AvailabilityZone" namespace="{$ns}">
					<xsl:value-of select="availabilityZone" />
				</xsl:element>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
