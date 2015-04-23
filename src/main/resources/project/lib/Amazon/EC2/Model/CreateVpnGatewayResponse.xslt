<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="CreateVpnGatewayResponse">
		<xsl:element name="CreateVpnGatewayResponse" namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="CreateVpnGatewayResult" namespace="{$ns}">
				<xsl:apply-templates select="vpnGateway" />
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match="vpnGateway">
		<xsl:element name="VpnGateway" namespace="{$ns}">
			<xsl:element name="VpnGatewayId" namespace="{$ns}">
				<xsl:value-of select="vpnGatewayId" />
			</xsl:element>
			<xsl:element name="VpnGatewayState" namespace="{$ns}">
				<xsl:value-of select="state" />
			</xsl:element>
			<xsl:element name="Type" namespace="{$ns}">
				<xsl:value-of select="type" />
			</xsl:element>
			<xsl:element name="AvailabilityZone" namespace="{$ns}">
				<xsl:value-of select="availabilityZone" />
			</xsl:element>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>

		  
