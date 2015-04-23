# Run this using this command in the ".../lib/EC2/Model" directory:
# sed -i.bak -f ../../amazon_EC2_XSLT_fix.sed *.xslt
#
# Note if this needs to be updated: remember to order the edits from most to least specific

s%value-of select="ec2:currentState/ec2:%value-of select="currentState/%
s%value-of select="ec2:monitoring/ec2:%value-of select="monitoring/%
s%value-of select="ec2:placement/ec2:%value-of select="placement/%
s%value-of select="ec2:previousState/ec2:%value-of select="previousState/%
s%value-of select="ec2:S3/ec2:%value-of select="S3/%
s%apply-templates select="ec2:%apply-templates select="%
s%for-each select="ec2:%for-each select="%
s%if test="ec2:%if test="%
s%if test="not(ec2:%if test="not(%
s%if test="string-length(ec2:%if test="string-length(%
s%template match="ec2:%template match="%
s%value-of select="ec2:%value-of select="%
s%value-of select="\.\./ec2:%value-of select="../%
