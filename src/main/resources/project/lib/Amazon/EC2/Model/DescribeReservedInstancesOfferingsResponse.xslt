<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeReservedInstancesOfferingsResponse">
        <xsl:element name="DescribeReservedInstancesOfferingsResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeReservedInstancesOfferingsResult" namespace="{$ns}">
                <xsl:apply-templates select="reservedInstancesOfferingsSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="reservedInstancesOfferingsSet">
        <xsl:for-each select="item">
            <xsl:element name="ReservedInstancesOffering" namespace="{$ns}">
                <xsl:element name="ReservedInstancesOfferingId" namespace="{$ns}">
                    <xsl:value-of select="reservedInstancesOfferingId"/>
                </xsl:element>
                <xsl:element name="InstanceType" namespace="{$ns}">
                    <xsl:value-of select="instanceType"/>
                </xsl:element>
                <xsl:element name="AvailabilityZone" namespace="{$ns}">
                    <xsl:value-of select="availabilityZone"/>
                </xsl:element>
                <xsl:element name="Duration" namespace="{$ns}">
                    <xsl:value-of select="duration"/>
                </xsl:element>
                <xsl:element name="UsagePrice" namespace="{$ns}">
                    <xsl:value-of select="usagePrice"/>
                </xsl:element>
                <xsl:element name="FixedPrice" namespace="{$ns}">
                    <xsl:value-of select="fixedPrice"/>
                </xsl:element>
                <xsl:element name="ProductDescription" namespace="{$ns}">
                    <xsl:value-of select="productDescription"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
