<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="CreateVolumeResponse">
        <xsl:element name="CreateVolumeResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="CreateVolumeResult" namespace="{$ns}">
                <xsl:element name="Volume" namespace="{$ns}">
                    <xsl:element name="VolumeId" namespace="{$ns}">
                        <xsl:value-of select="volumeId"/>
                    </xsl:element>
                    <xsl:element name="Size" namespace="{$ns}">
                        <xsl:value-of select="size"/>
                    </xsl:element>
                    <xsl:element name="SnapshotId" namespace="{$ns}">
                        <xsl:value-of select="snapshotId"/>
                    </xsl:element>
                    <xsl:element name="AvailabilityZone" namespace="{$ns}">
                        <xsl:value-of select="availabilityZone"/>
                    </xsl:element>
                    <xsl:element name="Status" namespace="{$ns}">
                        <xsl:value-of select="status"/>
                    </xsl:element>
                    <xsl:element name="CreateTime" namespace="{$ns}">
                        <xsl:value-of select="createTime"/>
                    </xsl:element>
                    <xsl:element name="Progress" namespace="{$ns}">
                        <xsl:value-of select="progress"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
