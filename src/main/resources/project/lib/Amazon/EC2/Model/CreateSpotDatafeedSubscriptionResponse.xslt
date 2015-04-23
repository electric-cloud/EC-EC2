<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
    exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
    <xsl:variable name="ns"
        select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
    <xsl:template match="CreateSpotDatafeedSubscriptionResponse">
        <xsl:element name="CreateSpotDatafeedSubscriptionResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId" />
                </xsl:element>
            </xsl:element>
            <xsl:element name="CreateSpotDatafeedSubscriptionResult" namespace="{$ns}">
                <xsl:apply-templates select="spotDatafeedSubscription"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="spotDatafeedSubscription">
            <xsl:element name="SpotDatafeedSubscription" namespace="{$ns}">
                <xsl:element name="OwnerId" namespace="{$ns}">
                    <xsl:value-of select="ownerId"/>
                </xsl:element>
                <xsl:element name="Bucket" namespace="{$ns}">
                    <xsl:value-of select="bucket"/>
                </xsl:element>
                <xsl:element name="Prefix" namespace="{$ns}">
                    <xsl:value-of select="prefix"/>
                </xsl:element>
                <xsl:element name="State" namespace="{$ns}">
                    <xsl:value-of select="state"/>
                </xsl:element>
                <xsl:apply-templates select="fault"/>
            </xsl:element>
    </xsl:template>
    <xsl:template match="fault">
        <xsl:element name="Fault" namespace="{$ns}">
            <xsl:element name="Code" namespace="{$ns}">
                <xsl:value-of select="code" />
            </xsl:element>
            <xsl:element name="Message" namespace="{$ns}">
                <xsl:value-of select="message" />
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
