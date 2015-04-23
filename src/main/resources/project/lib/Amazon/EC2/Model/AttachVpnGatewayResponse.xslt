<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="AttachVpnGatewayResponse">
		<xsl:element name="AttachVpnGatewayResponse" namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="AttachVpnGatewayResult" namespace="{$ns}">
				<xsl:apply-templates select="attachment" />
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<xsl:template match="attachment">
		<xsl:element name="VpcAttachment" namespace="{$ns}">
			<xsl:element name="VpcId" namespace="{$ns}">
				<xsl:value-of select="vpcId" />
			</xsl:element>
			<xsl:element name="VpcAttachmentState" namespace="{$ns}">
				<xsl:value-of select="state" />
			</xsl:element>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
