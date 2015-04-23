<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ec2="http://ec2.amazonaws.com/doc/2010-06-15/" exclude-result-prefixes="ec2">
    <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>
    <xsl:variable name="ns" select="'http://ec2.amazonaws.com/doc/2010-06-15/'"/>
    <xsl:template match="RunInstancesResponse">
        <xsl:element name="RunInstancesResponse" namespace="{$ns}">
            <xsl:element name="ResponseMetadata" namespace="{$ns}">
                <xsl:element name="RequestId" namespace="{$ns}">
                    <xsl:value-of select="requestId"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="RunInstancesResult" namespace="{$ns}">
                <xsl:element name="Reservation" namespace="{$ns}">
                    <xsl:element name="ReservationId" namespace="{$ns}">
                        <xsl:value-of select="reservationId"/>
                    </xsl:element>
                    <xsl:element name="OwnerId" namespace="{$ns}">
                        <xsl:value-of select="ownerId"/>
                    </xsl:element>
                    <xsl:element name="RequesterId" namespace="{$ns}">
                        <xsl:value-of select="requesterId"/>
                    </xsl:element>
                    <xsl:apply-templates select="groupSet"/>
                    <xsl:apply-templates select="instancesSet"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="groupSet">
        <xsl:for-each select="item">
            <xsl:element name="GroupName" namespace="{$ns}">
                <xsl:value-of select="groupId"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="instancesSet">
        <xsl:for-each select="item">
            <xsl:element name="RunningInstance" namespace="{$ns}">
                <xsl:element name="InstanceId" namespace="{$ns}">
                    <xsl:value-of select="instanceId"/>
                </xsl:element>
                <xsl:element name="ImageId" namespace="{$ns}">
                    <xsl:value-of select="imageId"/>
                </xsl:element>
                <xsl:apply-templates select="instanceState"/>
                <xsl:element name="PrivateDnsName" namespace="{$ns}">
                    <xsl:value-of select="privateDnsName"/>
                </xsl:element>
                <xsl:element name="PublicDnsName" namespace="{$ns}">
                    <xsl:value-of select="dnsName"/>
                </xsl:element>
                <xsl:element name="StateTransitionReason" namespace="{$ns}">
                    <xsl:value-of select="reason"/>
                </xsl:element>
                <xsl:element name="KeyName" namespace="{$ns}">
                    <xsl:value-of select="keyName"/>
                </xsl:element>
                <xsl:element name="AmiLaunchIndex" namespace="{$ns}">
                    <xsl:value-of select="amiLaunchIndex"/>
                </xsl:element>
                <xsl:apply-templates select="productCodes"/>
                <xsl:element name="InstanceType" namespace="{$ns}">
                    <xsl:value-of select="instanceType"/>
                </xsl:element>
                <xsl:element name="LaunchTime" namespace="{$ns}">
                    <xsl:value-of select="launchTime"/>
                </xsl:element>
                <xsl:element name="Placement" namespace="{$ns}">
                    <xsl:element name="AvailabilityZone" namespace="{$ns}">
                        <xsl:value-of select="placement/availabilityZone"/>
                    </xsl:element>
                    <xsl:element name="GroupName" namespace="{$ns}">
                      <xsl:value-of select="placement/groupName"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="KernelId" namespace="{$ns}">
                    <xsl:value-of select="kernelId"/>
                </xsl:element>
                <xsl:element name="RamdiskId" namespace="{$ns}">
                    <xsl:value-of select="ramdiskId"/>
                </xsl:element>
                <xsl:element name="Platform" namespace="{$ns}">
                    <xsl:value-of select="platform"/>
                </xsl:element>
                <xsl:element name="SubnetId" namespace="{$ns}">
                    <xsl:value-of select="subnetId"/>
                </xsl:element>
                <xsl:element name="VpcId" namespace="{$ns}">
                    <xsl:value-of select="vpcId"/>
                </xsl:element>
                <xsl:element name="PrivateIpAddress" namespace="{$ns}">
                    <xsl:value-of select="privateIpAddress"/>
                </xsl:element>
                <xsl:element name="IpAddress" namespace="{$ns}">
                    <xsl:value-of select="ipAddress"/>
                </xsl:element>
                <xsl:element name="Monitoring" namespace="{$ns}">
                    <xsl:element name="MonitoringState" namespace="{$ns}">
                        <xsl:value-of select="monitoring/state"/>
                    </xsl:element>
                </xsl:element>
                <xsl:apply-templates select="stateReason"/>
                <xsl:element name="Architecture" namespace="{$ns}">
                    <xsl:value-of select="architecture"/>
                </xsl:element>
                <xsl:element name="RootDeviceType" namespace="{$ns}">
                    <xsl:value-of select="rootDeviceType"/>
                </xsl:element>
                <xsl:element name="RootDeviceName" namespace="{$ns}">
                    <xsl:value-of select="rootDeviceName"/>
                </xsl:element>
                <xsl:apply-templates select="blockDeviceMapping"/>
                <xsl:element name="InstanceLifecycle" namespace="{$ns}">
                    <xsl:value-of select="instanceLifecycle"/>
                </xsl:element>
                <xsl:element name="SpotInstanceRequestId" namespace="{$ns}">
                    <xsl:value-of select="spotInstanceRequestId"/>
                </xsl:element>
                <xsl:element name="VirtualizationType" namespace="{$ns}">
                    <xsl:value-of select="virtualizationType"/>
                </xsl:element>
                <xsl:apply-templates select="license"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="license">
        <xsl:element name="License" namespace="{$ns}">
	         <xsl:element name="Pool" namespace="{$ns}">
	             <xsl:value-of select="pool"/>
	         </xsl:element>
        </xsl:element>
    </xsl:template>    
    <xsl:template match="productCodes">
        <xsl:for-each select="item">
            <xsl:element name="ProductCode" namespace="{$ns}">
                <xsl:value-of select="productCode"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="instanceState">
        <xsl:element name="InstanceState" namespace="{$ns}">
            <xsl:element name="Code" namespace="{$ns}">
                <xsl:value-of select="code"/>
            </xsl:element>
            <xsl:element name="Name" namespace="{$ns}">
                <xsl:value-of select="name"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="stateReason">
        <xsl:element name="StateReason" namespace="{$ns}">
            <xsl:element name="Code" namespace="{$ns}">
                <xsl:value-of select="code"/>
            </xsl:element>
            <xsl:element name="Message" namespace="{$ns}">
                <xsl:value-of select="message"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="blockDeviceMapping">
        <xsl:for-each select="item">
            <xsl:element name="BlockDeviceMapping" namespace="{$ns}">
                <xsl:element name="DeviceName" namespace="{$ns}">
                    <xsl:value-of select="deviceName"/>
                </xsl:element>
                <xsl:apply-templates select="ebs"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="ebs">
        <xsl:element name="Ebs" namespace="{$ns}">
            <xsl:element name="VolumeId" namespace="{$ns}">
                <xsl:value-of select="volumeId"/>
            </xsl:element>
            <xsl:element name="Status" namespace="{$ns}">
                <xsl:value-of select="status"/>
            </xsl:element>
            <xsl:element name="AttachTime" namespace="{$ns}">
                <xsl:value-of select="attachTime"/>
            </xsl:element>
            <xsl:element name="DeleteOnTermination" namespace="{$ns}">
                <xsl:if test="string-length(deleteOnTermination) = 0">false</xsl:if>
                <xsl:if test="string-length(deleteOnTermination) > 0">
                    <xsl:value-of select="deleteOnTermination"/>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
