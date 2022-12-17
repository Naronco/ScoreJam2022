#!/usr/bin/env dub
/++ dub.sdl:
name "genfont"
dependency "bmfont" version="*"
+/

import bmfont;
import std.stdio;

void main()
{
	dstring chars = ` !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_` ~ '`' ~ `abcdefghijklmnopqrstuvwxyz{|}~`d;
	int charWidth = 14;
	int charHeight = 28;

	Font font;
	font.pages = ["Font.png"];
	font.info.fontSize = 28;
	font.info.aa = 1;
	font.info.fontName = "WebFreaks Font";
	font.common.lineHeight = 24;
	font.common.base = 22;
	font.common.scaleW = 224;
	font.common.scaleH = 224;
	font.common.pages = 1;
	font.common.alphaChnl = ChannelType.glyph;
	font.common.redChnl = ChannelType.glyph;
	font.common.greenChnl = ChannelType.glyph;
	font.common.blueChnl = ChannelType.glyph;

	auto numCharsX = font.common.scaleW / charWidth;

	foreach (i, c; chars)
	{
		font.chars ~= Font.Char(c, cast(ushort)(i % numCharsX), cast(ushort)(i / numCharsX), cast(ushort)charWidth, cast(ushort)charHeight, 0, 0, cast(short)charWidth, 0, Channels.all);
	}

	writeln(font.toString);
}
