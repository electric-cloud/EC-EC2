<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="StartInstancesResponse">
        <xsl:element name="StartInstancesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="StartInstancesResult" namespace="{$ns}">
                <xsl:apply-templates select="instancesSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="instancesSet">
        <xsl:for-each select="item">
            <xsl:element name="StartingInstances" namespace="{$ns}">
                <xsl:element name="InstanceId" namespace="{$ns}">
                    <xsl:value-of select="instanceId"/>
                </xsl:element>
                <xsl:element name="CurrentState" namespace="{$ns}">
                    <xsl:element name="Code" namespace="{$ns}">
                        <xsl:value-of select="currentState/code"/>
                    </xsl:element>
                    <xsl:element name="Name" namespace="{$ns}">
                        <xsl:value-of select="currentState/name"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="PreviousState" namespace="{$ns}">
                    <xsl:element name="Code" namespace="{$ns}">
                        <xsl:value-of select="previousState/code"/>
                    </xsl:element>
                    <xsl:element name="Name" namespace="{$ns}">
                        <xsl:value-of select="previousState/name"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
