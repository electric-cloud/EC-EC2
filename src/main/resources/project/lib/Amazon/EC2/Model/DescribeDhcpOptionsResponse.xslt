<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="DescribeDhcpOptionsResponse">
		<xsl:element name="DescribeDhcpOptionsResponse" namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="DescribeDhcpOptionsResult" namespace="{$ns}">
				<xsl:apply-templates select="dhcpOptionsSet" />
			</xsl:element>
		</xsl:element>
	</xsl:template>



	<xsl:template match="dhcpOptionsSet">
		<xsl:for-each select="item">
			<xsl:element name="DhcpOptions" namespace="{$ns}">
				<xsl:element name="DhcpOptionsId" namespace="{$ns}">
					<xsl:value-of select="dhcpOptionsId" />
				</xsl:element>

				<xsl:apply-templates select="dhcpConfigurationSet" />
			</xsl:element>
		</xsl:for-each>
	</xsl:template>


	<xsl:template match="dhcpConfigurationSet">
		<xsl:for-each select="item">
			<xsl:element name="Configuration" namespace="{$ns}">
				<xsl:element name="Key" namespace="{$ns}">
					<xsl:value-of select="key" />
				</xsl:element>
        		<xsl:apply-templates select="valueSet" />
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="valueSet">
		<xsl:for-each select="item">
			<xsl:element name="Value" namespace="{$ns}">
				<xsl:value-of select="value" />
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
