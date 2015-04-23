<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/"
	exclude-result-prefixes="ec2">
	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" />
	<xsl:variable name="ns"
		select="'http://ec2.amazonaws.com/doc/2010-06-15/'" />
	<xsl:template match="DescribeSnapshotAttributeResponse">
		<xsl:element name="DescribeSnapshotAttributeResponse"
			namespace="{$ns}">
			<xsl:element name="ResponseMetadata" namespace="{$ns}">
				<xsl:element name="RequestId" namespace="{$ns}">
					<xsl:value-of select="requestId" />
				</xsl:element>
			</xsl:element>
			<xsl:element name="DescribeSnapshotAttributeResult"
				namespace="{$ns}">
				<xsl:element name="SnapshotAttribute" namespace="{$ns}">
					<xsl:element name="SnapshotId" namespace="{$ns}">
						<xsl:value-of select="snapshotId" />
					</xsl:element>
					<xsl:apply-templates select="createVolumePermission" />
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template match="createVolumePermission">
		<xsl:for-each select="item">
			<xsl:element name="CreateVolumePermission" namespace="{$ns}">
				<xsl:element name="UserId" namespace="{$ns}">
					<xsl:value-of select="userId" />
				</xsl:element>
				<xsl:element name="GroupName" namespace="{$ns}">
					<xsl:value-of select="group" />
				</xsl:element>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
