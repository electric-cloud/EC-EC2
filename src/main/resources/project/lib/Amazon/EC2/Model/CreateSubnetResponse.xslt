<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="CreateSubnetResponse">
		<xsl:element name="CreateSubnetResponse" namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="CreateSubnetResult" namespace="{$ns}">
				<xsl:apply-templates select="subnet" />
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match="subnet">
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
	</xsl:template>


</xsl:stylesheet>
