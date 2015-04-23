<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeReservedInstancesResponse">
        <xsl:element name="DescribeReservedInstancesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeReservedInstancesResult" namespace="{$ns}">
                <xsl:apply-templates select="reservedInstancesSet"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="reservedInstancesSet">
        <xsl:for-each select="item">
            <xsl:element name="ReservedInstances" namespace="{$ns}">
                <xsl:element name="ReservedInstancesId" namespace="{$ns}">
                    <xsl:value-of select="reservedInstancesId"/>
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
                <xsl:element name="InstanceCount" namespace="{$ns}">
                    <xsl:value-of select="instanceCount"/>
                </xsl:element>
                <xsl:element name="ProductDescription" namespace="{$ns}">
                    <xsl:value-of select="productDescription"/>
                </xsl:element>
                <xsl:element name="PurchaseState" namespace="{$ns}">
                    <xsl:value-of select="state"/>
                </xsl:element>
                <xsl:element name="StartTime" namespace="{$ns}">
                    <xsl:value-of select="start"/>
                </xsl:element>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
