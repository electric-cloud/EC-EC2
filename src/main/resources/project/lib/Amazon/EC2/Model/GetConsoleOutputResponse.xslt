<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="GetConsoleOutputResponse">
        <xsl:element name="GetConsoleOutputResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="GetConsoleOutputResult" namespace="{$ns}">
                <xsl:element name="ConsoleOutput" namespace="{$ns}">
                    <xsl:element name="InstanceId" namespace="{$ns}">
                        <xsl:value-of select="instanceId"/>
                    </xsl:element>
                    <xsl:element name="Timestamp" namespace="{$ns}">
                        <xsl:value-of select="timestamp"/>
                    </xsl:element>
                    <xsl:element name="Output" namespace="{$ns}">
                        <xsl:value-of select="output"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
