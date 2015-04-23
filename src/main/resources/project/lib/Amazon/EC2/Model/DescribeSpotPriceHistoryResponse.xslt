<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
    exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
    <xsl:variable name="ns"
        select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
    <xsl:template match="DescribeSpotPriceHistoryResponse">
        <xsl:element name="DescribeSpotPriceHistoryResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId" />
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeSpotPriceHistoryResult" namespace="{$ns}">
                <xsl:apply-templates select="spotPriceHistorySet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="spotPriceHistorySet">
        <xsl:for-each select="item">
            <xsl:element name="SpotPriceHistory" namespace="{$ns}">
                <xsl:element name="InstanceType" namespace="{$ns}">
                    <xsl:value-of select="instanceType"/>
                </xsl:element>
                <xsl:element name="ProductDescription" namespace="{$ns}">
                    <xsl:value-of select="productDescription"/>
                </xsl:element>
                <xsl:element name="SpotPrice" namespace="{$ns}">
                    <xsl:value-of select="spotPrice"/>
                </xsl:element>
                <xsl:element name="Timestamp" namespace="{$ns}">
                    <xsl:value-of select="timestamp"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
