<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="MonitorInstancesResponse">
        <xsl:element name="MonitorInstancesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="MonitorInstancesResult" namespace="{$ns}">
                <xsl:apply-templates select="instancesSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="instancesSet">
        <xsl:for-each select="item">
            <xsl:element name="InstanceMonitoring" namespace="{$ns}">
                <xsl:element name="InstanceId" namespace="{$ns}">
                    <xsl:value-of select="instanceId"/>
                </xsl:element>
                <xsl:element name="Monitoring" namespace="{$ns}">
                    <xsl:element name="MonitoringState" namespace="{$ns}">
                        <xsl:value-of select="monitoring/state"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
