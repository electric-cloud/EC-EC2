<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeKeyPairsResponse">
        <xsl:element name="DescribeKeyPairsResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeKeyPairsResult" namespace="{$ns}">
                <xsl:apply-templates select="keySet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="keySet">
        <xsl:for-each select="item">
            <xsl:element name="KeyPair" namespace="{$ns}">
                <xsl:element name="KeyName" namespace="{$ns}">
                    <xsl:value-of select="keyName"/>
                </xsl:element>
                <xsl:element name="KeyFingerprint" namespace="{$ns}">
                    <xsl:value-of select="keyFingerprint"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
