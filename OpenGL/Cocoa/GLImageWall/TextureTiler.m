//
//  TextureTiler.m
//  GLImageSplitter
//
//  Created on 3/3/06.
//
//	Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//	Computer, Inc. ("Apple") in consideration of your agreement to the
//	following terms, and your use, installation, modification or
//	redistribution of this Apple software constitutes acceptance of these
//	terms.  If you do not agree with these terms, please do not use,
//	install, modify or redistribute this Apple software.
//
//	In consideration of your agreement to abide by the following terms, and
//	subject to these terms, Apple grants you a personal, non-exclusive
//	license, under Apple's copyrights in this original Apple software (the
//	"Apple Software"), to use, reproduce, modify and redistribute the Apple
//	Software, with or without modifications, in source and/or binary forms;
//	provided that if you redistribute the Apple Software in its entirety and
//	without modifications, you must retain this notice and the following
//	text and disclaimers in all such redistributions of the Apple Software. 
//	Neither the name, trademarks, service marks or logos of Apple Computer,
//	Inc. may be used to endorse or promote products derived from the Apple
//	Software without specific prior written permission from Apple.  Except
//	as expressly stated in this notice, no other rights or licenses, express
//	or implied, are granted by Apple herein, including but not limited to
//	any patent rights that may be infringed by your derivative works or by
//	other works in which the Apple Software may be incorporated.
//
//	The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//	MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//	THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//	FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//	OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//	IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//	INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//	MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//	AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//	STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//	POSSIBILITY OF SUCH DAMAGE.
//
//	Copyright (c) 2006 Apple Computer, Inc., All rights reserved.
//

#import "TextureTiler.h"

#include "VariousUtilities.h"

//This class handles texture loading and drawing -- it also tiles
//(Tiled textures with borders do not work quite right)

//One of these exists per display (it would be better to make them per renderer and share contexts)
//TODO: These should be shared if contexts are shared across views...

//NOTE: borders do not work well... -- the edges look ugly
//maybe my math is off on either drawing or creating...

@implementation TextureTiler

- init
{
	self=[super init];
	if(self)
	{
		borders=0;
		numWidth=0;
		numTextureNames=0;
		textureNames=NULL;
	}
	return self;
}

- (void)dealloc
{
	//should also free the textures in opengl
	[self freeTextures];
    [super dealloc];
}

- (void)freeTextures
{
	//free old textures
	if(textureNames)
	{
		//The context used to create these must be set current to destroy them
		//TODO save current context
		//TODO set current context to context that created these textures
		int textureTarget=GL_TEXTURE_2D;
		glEnable(textureTarget);
glReportError();
		glDeleteTextures(numTextureNames,textureNames);
glReportError();
		free(textureNames);
		//TODO restore current context
	}
}

//Load Tiled texture
- (void)textureChanged:(NSImage*)image tileSize:(int)newTileSize AGPTexturing:(int)AGPTexturing borders:(int)newBorders
{
	if(image)
	{
		//TODO retain current context

		//int textureUnitIndex=GL_TEXTURE0;
		int textureTarget=GL_TEXTURE_2D;
		NSBitmapImageRep* bitmap=nil;

		//get the bitmap representation
		bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];

		[self freeTextures];

		// Non-planar, RGB 24 bit bitmap, or RGBA 32 bit bitmap
		int samplesPerPixel=[bitmap samplesPerPixel];

		int supported;
		GLenum type;
		switch([bitmap bitsPerSample])
		{
		case 8:
			type=GL_UNSIGNED_BYTE;
			supported=1;
			break;
		case 16:
			type=GL_UNSIGNED_SHORT;
			supported=1;
			break;
		default:
			//unknown crazy format
			supported=0;
			break;
		}

		if(![bitmap isPlanar]&&(samplesPerPixel==3||samplesPerPixel==4)&&supported)
		{
			//make new textures
			float width=[bitmap pixelsWide];
			float height=[bitmap pixelsHigh];
//NSLog(@"%g x %g",width,height);

			borders=newBorders?1:0;
			newTileSize-=2*borders;
			textureSize=NSMakeSize(width,height);
			tileSize=NSMakeSize(newTileSize,newTileSize);

			int perWidth=(int)ceil(width/tileSize.width);
			int perHeight=(int)ceil(height/tileSize.height);

			numWidth=perWidth;
			numTextureNames=perWidth*perHeight;
			textureNames=malloc(sizeof(GLuint)*numTextureNames);
			glGenTextures(numTextureNames,textureNames);
glReportError();

			//backup default pixel store state
			glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
glReportError();

			glEnable(textureTarget);
glReportError();
			int maxX=perWidth;
			int maxY=perHeight;

			int onY;
			for(onY=0;onY<maxY;onY++)
			{
				int onX;
				for(onX=0;onX<maxX;onX++)
				{
					int onTexture=onY*maxX+onX;

					//setup offsets
					int x=onX*tileSize.width;
					int y=onY*tileSize.height;

					//setup extents
					int dx=MINOF2(width-x,tileSize.width);
					int dy=MINOF2(height-y,tileSize.height);

					//setup bitmap attributes
					glPixelStorei(GL_UNPACK_ROW_LENGTH,width);
glReportError();
//					glPixelStorei(GL_UNPACK_IMAGE_HEIGHT,height);
//glReportError();
					glPixelStorei(GL_UNPACK_ALIGNMENT,1);
glReportError();
					//skip to x,y for read from bitmap
					glPixelStorei(GL_UNPACK_SKIP_PIXELS,x);
glReportError();
					glPixelStorei(GL_UNPACK_SKIP_ROWS,y);
glReportError();

					glBindTexture(textureTarget,textureNames[onTexture]);
glReportError();

					//setup tex params
					float texturePriority=AGPTexturing?1.0f:0.0f;
					glTexParameterf(textureTarget,GL_TEXTURE_PRIORITY,texturePriority);//AGP texturing or no?
glReportError();
					glTexParameteri(textureTarget,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
glReportError();
					glTexParameteri(textureTarget,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
glReportError();
					glTexParameteri(textureTarget,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
glReportError();
					glTexParameteri(textureTarget,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
glReportError();

					//read to x+dx,y+dy
					//make texture of the correct size
					glTexImage2D(textureTarget,0,samplesPerPixel==4?GL_RGBA8:GL_RGB8,tileSize.width+2*borders,tileSize.height+2*borders,0,samplesPerPixel==4?GL_RGBA:GL_RGB,type,NULL);
glReportError();
//printf("main(%d %d) skip(%d %d) offset(%d %d) extents(%d %d)\n",onX,onY,x,y,borders,borders,dx,dy);
					//copy data into texture
					glTexSubImage2D(textureTarget,0,borders,borders,dx,dy,samplesPerPixel==4?GL_RGBA:GL_RGB,type,[bitmap bitmapData]);
glReportError();
					if(borders)
					{
						//edge cases need borders of their extended 
						//the 4 other rects -- each one around the main texture data (they are the borders) -- all one pixel by n pixels
						//bitmap offsets
						//fix for borders -- in bitmap coords (like x,y)
						int borderMinX=MAXOF2(x-1,0);
						int borderMaxX=MINOF2(width-1,x+dx);
						int borderDx=borderMaxX-borderMinX+1;
						int borderMinY=MAXOF2(y-1,0);
						int borderMaxY=MINOF2(height-1,y+dy);
						int borderDy=borderMaxY-borderMinY+1;
										//minX		//maxX		//minY		//maxY
						int skipXs[]=	{borderMinX,borderMaxX,	borderMinX,	borderMinX};
						int skipYs[]=	{borderMinY,borderMinY,	borderMinY,	borderMaxY};
						//texture offsets
						int xOffsets[]=	{0,					dx+1,				1-(x-borderMinX),	1-(x-borderMinX)};
						int yOffsets[]=	{1-(y-borderMinY),	1-(y-borderMinY),	0,					dy+1};
						//extents
						int widths[]=	{1,			1,			borderDx,	borderDx};
						int heights[]=	{borderDy,	borderDy,	1,			1};

						//get border data
						int onBorder;
						for(onBorder=0;onBorder<sizeof(xOffsets)/sizeof(xOffsets[0]);onBorder++)
						{
							//skip to x,y
							glPixelStorei(GL_UNPACK_SKIP_PIXELS,skipXs[onBorder]);
glReportError();
							glPixelStorei(GL_UNPACK_SKIP_ROWS,skipYs[onBorder]);
glReportError();
//printf("border(%d %d)[%d] skip(%d %d) offset(%d %d) extents(%d %d)\n",onX,onY,onBorder,skipXs[onBorder],skipYs[onBorder],xOffsets[onBorder],yOffsets[onBorder],widths[onBorder],heights[onBorder]);
							glTexSubImage2D(textureTarget,0,xOffsets[onBorder],yOffsets[onBorder],widths[onBorder],heights[onBorder],samplesPerPixel==4?GL_RGBA:GL_RGB,type,[bitmap bitmapData]);
glReportError();
						}
					}
				}
			}
			glDisable(textureTarget);
glReportError();
			//restore default pixel store state
			glPopClientAttrib();
glReportError();
		}
		else
		{
			/*
				Error condition...
				The above code handles 2 cases (24 bit RGB and 32 bit RGBA),
				it is possible to support other bitmap formats if desired.
				
				So we'll log out some useful information.
			*/
			NSLog (@"-textureChanged: Unsupported bitmap data format: isPlanar:%d, samplesPerPixel:%d, bitsPerPixel:%d, bytesPerRow:%d, bytesPerPlane:%d",[bitmap isPlanar],[bitmap samplesPerPixel],[bitmap bitsPerPixel],[bitmap bytesPerRow],[bitmap bytesPerPlane]);
		}
		[bitmap release];
	}
}

//Render Tiled Texture
- (void)render:(BOOL)wireframe
{
	GLenum type=wireframe==YES?GL_LINE_LOOP:GL_QUADS;

	if(textureNames)
	{
		//flip image
		glScalef(1.0,-1.0,1.0);
glReportError();

		//scale to image size -- but dont distort

		//Use the smallest size -- will not cutoff image -- guaranteed safety
		//float imageScale=MINOF2(2.0/textureSize.width,2.0/textureSize.height);

		//Use the largest size -- could cutoff part of image -- safety not guaranteed
		float imageScale=MAXOF2(4.0/textureSize.width,4.0/textureSize.height);

		glScalef(imageScale,imageScale,imageScale);
glReportError();

		//shift to center of image
		glTranslatef(-textureSize.width/2.0,-textureSize.height/2.0,0);
glReportError();

		int textureUnitIndex=GL_TEXTURE0;
		int textureTarget=GL_TEXTURE_2D;

		int maxX=numWidth;
		int maxY=numTextureNames/numWidth;

		glEnable(textureTarget);
glReportError();
		glColor3f(1,1,1);//white polygons
glReportError();
		glActiveTexture(textureUnitIndex);
glReportError();

		int onY;
		for(onY=0;onY<maxY;onY++)
		{
			int onX;
			for(onX=0;onX<maxX;onX++)
			{
				int onTexture=onY*maxX+onX;

				//setup offsets
				float x=onX*tileSize.width;
				float y=onY*tileSize.height;

				//setup extents
				float dx=MINOF2(textureSize.width-x,tileSize.width);
				float dy=MINOF2(textureSize.height-y,tileSize.height);

				float bordersFloat=(float)borders;

				//setup tex coords
				float usableTextureWidth=dx+2.0*bordersFloat;
				float usableTextureHeight=dy+2.0*bordersFloat;

				float fullTextureWidth=tileSize.width+2.0*bordersFloat;
				float fullTextureHeight=tileSize.height+2.0*bordersFloat;

				float u=bordersFloat/fullTextureWidth;
				float v=bordersFloat/fullTextureHeight;

				//draw the overlaps if there are any
				float du=usableTextureWidth/fullTextureWidth-u;
				float dv=usableTextureHeight/fullTextureHeight-v;

				glBindTexture(textureTarget,textureNames[onTexture]);
glReportError();
				glBegin(type);
				glMultiTexCoord2f(textureUnitIndex,u,v);
				glVertex2f(x,y);
				glMultiTexCoord2f(textureUnitIndex,du,u);
				glVertex2f(x+dx,y);
				glMultiTexCoord2f(textureUnitIndex,du,dv);
				glVertex2f(x+dx,y+dy);
				glMultiTexCoord2f(textureUnitIndex,u,dv);
				glVertex2f(x,y+dy);
				glEnd();
glReportError();
			}
		}
		glDisable(textureTarget);
glReportError();
	}
	else
	{
		//No texture .: draw a perty quad!
		glBegin(type);
		glColor3f(1,0,0);
		glVertex2f(-1,-1);
		glColor3f(0,1,0);
		glVertex2f(+1,-1);
		glColor3f(1,1,1);
		glVertex2f(+1,+1);
		glColor3f(0,0,1);
		glVertex2f(-1,+1);
		glEnd();
glReportError();
	}
}

@end
