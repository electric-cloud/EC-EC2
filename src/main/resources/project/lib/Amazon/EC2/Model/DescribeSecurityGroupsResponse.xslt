<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="DescribeSecurityGroupsResponse">
        <xsl:element name="DescribeSecurityGroupsResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="DescribeSecurityGroupsResult" namespace="{$ns}">
                <xsl:apply-templates select="securityGroupInfo"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="securityGroupInfo">
        <xsl:for-each select="item">
            <xsl:element name="SecurityGroup" namespace="{$ns}">
                <xsl:element name="OwnerId" namespace="{$ns}">
                    <xsl:value-of select="ownerId"/>
                </xsl:element>
                <xsl:element name="GroupName" namespace="{$ns}">
                    <xsl:value-of select="groupName"/>
                </xsl:element>
                <xsl:element name="GroupDescription" namespace="{$ns}">
                    <xsl:value-of select="groupDescription"/>
                </xsl:element>
                <xsl:apply-templates select="ipPermissions"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="ipPermissions">
        <xsl:for-each select="item">
            <xsl:element name="IpPermission" namespace="{$ns}">
                <xsl:element name="IpProtocol" namespace="{$ns}">
                    <xsl:value-of select="ipProtocol"/>
                </xsl:element>
                <xsl:element name="FromPort" namespace="{$ns}">
                    <xsl:value-of select="fromPort"/>
                </xsl:element>
                <xsl:element name="ToPort" namespace="{$ns}">
                    <xsl:value-of select="toPort"/>
                </xsl:element>
                <xsl:apply-templates select="ipRanges"/>
                <xsl:apply-templates select="groups"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="groups">
        <xsl:for-each select="item">
            <xsl:element name="UserIdGroupPair" namespace="{$ns}">
                <xsl:element name="UserId" namespace="{$ns}">
                    <xsl:value-of select="userId"/>
                </xsl:element>
                <xsl:element name="GroupName" namespace="{$ns}">
                    <xsl:value-of select="groupName"/>
                </xsl:element>
                <xsl:apply-templates select="ipRanges"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="ipRanges">
        <xsl:for-each select="item">
            <xsl:element name="IpRange" namespace="{$ns}">
                <xsl:value-of select="cidrIp"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
