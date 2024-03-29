<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output omit-xml-declaration="yes" indent="no" />
  <xsl:param name="consecutiveMessage" />
  <xsl:param name="bulkTransform" />
  <xsl:param name="timeFormat" />

  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="$consecutiveMessage = 'yes'">
        <xsl:apply-templates select="/envelope/message[last()]" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="member-link">
    <xsl:param name="member" />
    <xsl:variable name="magic">219078271633797408737459358</xsl:variable>
    <xsl:variable name="normal" select="normalize-space(translate($member, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ-[]\`_^{|}', 'abcdefghijklmnopqrstuvwxyz          '))" />
    <xsl:variable name="hash" select="number(translate($normal, 'abcdefghijklmnopqrstuvwxyz ', $magic))" />

    <xsl:variable name="memberClasses">
      <xsl:text>member</xsl:text>
      <xsl:if test="sender/@self = 'yes' or ../sender/@self = 'yes'">
        <xsl:text> self</xsl:text>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="memberLink">
      <xsl:choose>
        <xsl:when test="sender/@identifier or ../sender/@identifier">
          <xsl:text>member:identifier:</xsl:text><xsl:value-of select="sender/@identifier | ../sender/@identifier" />
        </xsl:when>
        <xsl:when test="sender/@nickname or ../sender/@nickname">
          <xsl:text>member:</xsl:text><xsl:value-of select="sender/@nickname | ../sender/@nickname" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>member:</xsl:text><xsl:value-of select="sender | ../sender" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a href="{$memberLink}" class="{$memberClasses}" style="color: hsl({$hash mod 359}, 54%, 42%)"><xsl:value-of select="$member" /></a>
  </xsl:template>

  <xsl:template match="envelope | message">
    <xsl:variable name="envelopeClasses">
      <xsl:text>envelope</xsl:text>
      <xsl:if test="message[1]/@highlight = 'yes' or @highlight = 'yes'">
        <xsl:text> highlight</xsl:text>
      </xsl:if>
      <xsl:if test="message[1]/@action = 'yes' or @action = 'yes'">
        <xsl:text> action</xsl:text>
      </xsl:if>
      <xsl:if test="message[1]/@type = 'notice' or @type = 'notice'">
        <xsl:text> notice</xsl:text>
      </xsl:if>
      <xsl:if test="message[1]/@ignored = 'yes' or @ignored = 'yes' or ../@ignored = 'yes'">
        <xsl:text> ignore</xsl:text>
      </xsl:if>
    </xsl:variable>

    <div id="{message[1]/@id | @id}" class="{$envelopeClasses}">
      <div class="timestamp">
        <xsl:call-template name="short-time">
          <xsl:with-param name="date" select="message[1]/@received | @received" />
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </div>
      <div class="who">
        <span class="dingbat">
          <xsl:choose>
            <xsl:when test="message[1]/@action = 'yes' or @action = 'yes'">• </xsl:when>
            <xsl:otherwise>&lt;</xsl:otherwise>
          </xsl:choose>
        </span>
        <xsl:call-template name="member-link">
          <xsl:with-param name="member" select="sender | ../sender" />
        </xsl:call-template>
        <span class="dingbat">
          <xsl:choose>
            <xsl:when test="message[1]/@action = 'yes' or @action = 'yes'">
              <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>&gt; </xsl:otherwise>
          </xsl:choose>
        </span>
      </div>
      <div class="message">
        <xsl:choose>
          <xsl:when test="message[1]">
            <xsl:apply-templates select="message[1]/child::node()" mode="copy" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="child::node()" mode="copy" />
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </div>

    <xsl:apply-templates select="message[position() &gt; 1]" />
  </xsl:template>

  <xsl:template match="event">
    <div class="event">
      <div class="timestamp">
        <xsl:call-template name="short-time">
          <xsl:with-param name="date" select="message[1]/@occured | @occurred" />
        </xsl:call-template>
      </div>
      <xsl:if test="who | ../who">
        <div class="who">
          <xsl:text>◦ </xsl:text>
          <xsl:call-template name="member-link">
            <xsl:with-param name="member" select="who | ../who" />
          </xsl:call-template>
        </div>
      </xsl:if>
      <div class="message">
        <xsl:apply-templates select="message/child::node()" mode="event" />
        <xsl:if test="string-length(reason)">
          <span class="reason">
            <xsl:text> (</xsl:text>
            <xsl:apply-templates select="reason/child::node()" mode="copy"/>
            <xsl:text>)</xsl:text>
          </span>
        </xsl:if>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="div[contains(@class,'member')]" mode="event">
    <xsl:variable name="nickname" select="current()" />
    <xsl:variable name="hostmask" select="../../mask" />
    <xsl:if test="$hostmask">
      <xsl:if test="../../@name = 'memberJoined' or ../../@name = 'memberParted'">
        <span class="hostmask">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$hostmask" />
          <xsl:text>) </xsl:text>
        </span>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="div[contains(@class,'member')]" mode="copy">
    <xsl:call-template name="member-link">
      <xsl:with-param name="member" select="current()" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="@*|*" mode="event">
    <xsl:copy><xsl:apply-templates select="@*|node()" mode="event" /></xsl:copy>
  </xsl:template>

  <xsl:template match="@*|*" mode="copy">
    <xsl:copy><xsl:apply-templates select="@*|node()" mode="copy" /></xsl:copy>
  </xsl:template>

  <xsl:template name="short-time">
    <xsl:param name="date" /> <!-- YYYY-MM-DD HH:MM:SS +/-HHMM -->
    <xsl:variable name='hour' select='substring($date, 12, 2)' />
    <xsl:variable name='minute' select='substring($date, 15, 2)' />
    <xsl:choose>
      <xsl:when test="contains($timeFormat,'a')">
        <!-- am/pm format -->
        <xsl:choose>
          <xsl:when test="number($hour) &gt; 12">
            <xsl:value-of select="number($hour) - 12" />
          </xsl:when>
          <xsl:when test="number($hour) = 0">
            <xsl:text>12</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$hour" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="$minute" />
        <xsl:choose>
          <xsl:when test="number($hour) &gt;= 12">
            <xsl:text>pm</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>am</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- 24hr format -->
        <xsl:value-of select="concat($hour,':',$minute)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
