<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2013-10-15/'"/>
    <xsl:template match="DescribeAccountAttributesResponse">
        <xsl:element name="DescribeAccountAttributesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeAccountAttributesResult" namespace="{$ns}">
                <xsl:apply-templates select="accountAttributeSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="accountAttributeSet">
        <xsl:apply-templates select="item"/>
    </xsl:template>
    <xsl:template match="item">
        <xsl:element name="AccountAttribute">
            <xsl:element name="AttributeName" namespace="{$ns}">
                    <xsl:value-of select="attributeName"/>
            </xsl:element>
            <xsl:apply-templates select="attributeValueSet"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="attributeValueSet">
     <xsl:for-each select="item">
        <xsl:element name="AttributeValue" namespace="{$ns}">
            <xsl:value-of select="attributeValue" />
        </xsl:element>
    </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
