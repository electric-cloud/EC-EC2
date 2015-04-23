<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeBundleTasksResponse">
        <xsl:element name="DescribeBundleTasksResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeBundleTasksResult" namespace="{$ns}">
                <xsl:apply-templates select="bundleInstanceTasksSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="bundleInstanceTasksSet">
        <xsl:for-each select="item">
            <xsl:element name="BundleTask" namespace="{$ns}">
                <xsl:element name="InstanceId" namespace="{$ns}">
                    <xsl:value-of select="instanceId"/>
                </xsl:element>
                <xsl:element name="BundleId" namespace="{$ns}">
                    <xsl:value-of select="bundleId"/>
                </xsl:element>
                <xsl:element name="BundleState" namespace="{$ns}">
                    <xsl:value-of select="state"/>
                </xsl:element>
                <xsl:element name="StartTime" namespace="{$ns}">
                    <xsl:value-of select="startTime"/>
                </xsl:element>
                <xsl:element name="UpdateTime" namespace="{$ns}">
                    <xsl:value-of select="updateTime"/>
                </xsl:element>
                <xsl:apply-templates select="storage"/>
                <xsl:element name="Progress" namespace="{$ns}">
                    <xsl:value-of select="progress"/>
                </xsl:element>
                <xsl:apply-templates select="error"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="storage">
        <xsl:element name="Storage" namespace="{$ns}">
            <xsl:element name="S3" namespace="{$ns}">
                <xsl:element name="Bucket" namespace="{$ns}">
                    <xsl:value-of select="S3/bucket"/>
                </xsl:element>
                <xsl:element name="Prefix" namespace="{$ns}">
                    <xsl:value-of select="S3/prefix"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="error">
        <xsl:element name="BundleTaskError" namespace="{$ns}">
            <xsl:element name="Code" namespace="{$ns}">
                <xsl:value-of select="code"/>
            </xsl:element>
            <xsl:element name="Message" namespace="{$ns}">
                <xsl:value-of select="message"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
