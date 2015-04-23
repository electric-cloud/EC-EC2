<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeCustomerGatewaysResponse">
        <xsl:element name="DescribeCustomerGatewaysResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeCustomerGatewaysResult" namespace="{$ns}">
                <xsl:apply-templates select="customerGatewaySet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="customerGatewaySet">
        <xsl:apply-templates select="item"/>
    </xsl:template>
    <xsl:template match="item">
		<xsl:element name="CustomerGateway" namespace="{$ns}">
			<xsl:element name="CustomerGatewayId" namespace="{$ns}">
				<xsl:value-of select="customerGatewayId" />
			</xsl:element>
			<xsl:element name="CustomerGatewayState" namespace="{$ns}">
				<xsl:value-of select="state" />
			</xsl:element>
			<xsl:element name="Type" namespace="{$ns}">
				<xsl:value-of select="type" />
			</xsl:element>
			<xsl:element name="IpAddress" namespace="{$ns}">
				<xsl:value-of select="ipAddress" />
			</xsl:element>
			<xsl:element name="BgpAsn" namespace="{$ns}">
				<xsl:value-of select="bgpAsn" />
			</xsl:element>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
