<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeAvailabilityZonesResponse">
        <xsl:element name="DescribeAvailabilityZonesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeAvailabilityZonesResult" namespace="{$ns}">
                <xsl:apply-templates select="availabilityZoneInfo"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="availabilityZoneInfo">
        <xsl:apply-templates select="item"/>
    </xsl:template>
    <xsl:template match="item">
        <xsl:element name="AvailabilityZone" namespace="{$ns}">
            <xsl:element name="ZoneName" namespace="{$ns}">
                <xsl:value-of select="zoneName"/>
            </xsl:element>
            <xsl:element name="ZoneState" namespace="{$ns}">
                <xsl:value-of select="zoneState"/>
            </xsl:element>
			<xsl:element name="RegionName" namespace="{$ns}">
				<xsl:value-of select="regionName" />
			</xsl:element>
			<xsl:apply-templates select="messageSet"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="messageSet">
	 <xsl:for-each select="item">
		<xsl:element name="Message" namespace="{$ns}">
			<xsl:value-of select="message" />
        </xsl:element>
    </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>


