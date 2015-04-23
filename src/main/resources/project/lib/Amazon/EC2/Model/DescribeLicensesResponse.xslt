<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeLicensesResponse">
        <xsl:element name="DescribeLicensesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeLicensesResult" namespace="{$ns}">
                <xsl:apply-templates select="licenseSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
	<xsl:template match="licenseSet">
        <xsl:for-each select="item">
            <xsl:element name="License" namespace="{$ns}">
                <xsl:element name="LicenseId" namespace="{$ns}">
                    <xsl:value-of select="licenseId"/>
                </xsl:element>
                <xsl:element name="Type" namespace="{$ns}">
                    <xsl:value-of select="type"/>
                </xsl:element>
                <xsl:element name="Pool" namespace="{$ns}">
                    <xsl:value-of select="pool"/>
                </xsl:element>
                <xsl:apply-templates select="capacitySet"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="capacitySet">
    	<xsl:for-each select="item">
    		<xsl:element name="LicenseCapacity" namespace="{$ns}">
    			<xsl:element name="Capacity" namespace="{$ns}">
                    <xsl:value-of select="capacity"/>
                </xsl:element>
    			<xsl:element name="InstanceCapacity" namespace="{$ns}">
                    <xsl:value-of select="instanceCapacity"/>
                </xsl:element>
    			<xsl:element name="State" namespace="{$ns}">
                    <xsl:value-of select="state"/>
                </xsl:element>
    			<xsl:element name="EarliestAllowedDeactivationTime" namespace="{$ns}">
                    <xsl:value-of select="earliestAllowedDeactivationTime"/>
                </xsl:element>
    		</xsl:element>
    	</xsl:for-each>
    </xsl:template>    
</xsl:stylesheet>    
