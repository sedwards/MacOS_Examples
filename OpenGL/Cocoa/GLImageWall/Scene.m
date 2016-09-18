//
//  Scene.m
//  GLImageSplitter
//
//  Created	on 2/26/06.
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

#import "Scene.h"
#import <OpenGL/glu.h>

#include "VariousUtilities.h"

//This class is our scene data

@implementation Scene

- (void)reset
{
	translation.x=0.0;
	translation.y=0.0;
	translation.z=-4.0;
	rotation.x=0.0;//start flipped
	rotation.y=0.0;
	rotation.z=0.0;
	scale.x=1.0;
	scale.y=1.0;
	scale.z=1.0;
	animating=NO;
	animationTime=0.0;
	wireframe=NO;
	mirror=NO;
	text=YES;
	help=YES;
}

- init
{
	self=[super init];
	if(self)
	{
		[self reset];
	}
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)animating
{
	return animating;
}

- (BOOL)fullscreen
{
	return fullscreen;
}

- (void)setFullscreen:(BOOL)newFullscreen
{
	fullscreen=newFullscreen;
}

- (void)setViewportRect:(NSRect)bounds virtualBounds:(NSRect)virtualBounds mainBounds:(NSRect)mainBounds
{
	glViewport(0,0,bounds.size.width,bounds.size.height);
glReportError();

	glMatrixMode(GL_PROJECTION);
glReportError();
	glLoadIdentity();
glReportError();

	GLdouble fovy=30.0;
	GLdouble aspect=mainBounds.size.width/mainBounds.size.height;
	GLdouble zNear=1.0;
	GLdouble zFar=1000.0;
	if(mirror)
	{
		gluPerspective(fovy,aspect,zNear,zFar);
glReportError();
	}
	else
	{
		//Tiled gluPerspective
		GLdouble xmin;
		GLdouble xmax;
		GLdouble ymin;
		GLdouble ymax;
		ymax=zNear*tan(fovy*M_PI/360.0);
		ymin=-ymax;
		xmin=ymin*aspect;
		xmax=ymax*aspect;

		//Tiled gluFrustum
		GLdouble l=xmin;
		GLdouble r=xmax;
		GLdouble b=ymin;
		GLdouble t=ymax;
		GLdouble n=zNear;
		GLdouble f=zFar;

		GLdouble left=l+(r-l)*(virtualBounds.origin.x-mainBounds.origin.x)/mainBounds.size.width;
		GLdouble right=left+(r-l)*virtualBounds.size.width/mainBounds.size.width;
		GLdouble bottom=b+(t-b)*(virtualBounds.origin.y-mainBounds.origin.y)/mainBounds.size.height;
		GLdouble top=bottom+(t-b)*virtualBounds.size.height/mainBounds.size.height;
		GLdouble near=n;
		GLdouble far=f;

		glFrustum(left,right,bottom,top,near,far);
glReportError();
		//ortho does not need the perspective stuff above...
		//glOrtho(left,right,bottom,top,near,far);
	}

	glMatrixMode(GL_MODELVIEW);
glReportError();
	glLoadIdentity();
glReportError();
}

- (void)drawText:(StringTexture*)helpString textString:(StringTexture*)textString
{	
	GLint matrixMode;
	GLboolean depthTest=glIsEnabled(GL_DEPTH_TEST);

	GLfloat viewport[4];
	glGetFloatv(GL_VIEWPORT,viewport);
	GLfloat width=viewport[2];
	GLfloat height=viewport[3];
	
	glDisable(GL_DEPTH_TEST); // ensure text is not remove by deoth buffer test.
	glEnable(GL_BLEND); // for text fading
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	// set orthograhic 1:1 pixel transform in local view coords
	glGetIntegerv(GL_MATRIX_MODE,&matrixMode);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	{
		glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
		{
			glLoadIdentity();
			glScalef(2.0f/width,-2.0f/height,1.0f);
			glTranslatef(-width/2.0f,-height/2.0f,0.0f);
			
			glColor4f(1.0f,1.0f,1.0f,1.0f);
			if(help)
			{
				[helpString drawAtPoint:NSMakePoint(floor((width-[helpString frameSize].width)/2.0f),floor((height-[helpString frameSize].height)/3.0f))];
			}
			if(text)
			{
				[textString drawAtPoint:NSMakePoint(10.0f,height-[textString frameSize].height-10.0f)];
			}
		}
		// reset orginal martices
		glPopMatrix(); // GL_MODELVIEW
		glMatrixMode(GL_PROJECTION);
	}
	glPopMatrix();
	glMatrixMode(matrixMode);

	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	glDisable(GL_BLEND);
	if(depthTest)
	{
		glEnable(GL_DEPTH_TEST);
	}
glReportError();
}

- (void)renderWithTextureTiler:(TextureTiler*)textureTiler helpString:(StringTexture*)helpString textString:(StringTexture*)textString
{
	glClearColor(0.0,0.0,0.0,0.0);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

	glPushMatrix();
	{
		glTranslatef(translation.x,translation.y,translation.z);
		if(animating)
		{
			animationTime+=0.1;
		}
		glRotatef(rotation.x+animationTime,1.0f,0.0f,0.0f);
		glRotatef(rotation.y+animationTime,0.0f,1.0f,0.0f);
		glRotatef(rotation.z+animationTime,0.0f,0.0f,1.0f);

		glScalef(scale.x,scale.y,scale.z);
		[textureTiler render:wireframe];
	}
	glPopMatrix();

	[self drawText:helpString textString:textString];

	glFinish();
}

- (void)keyDown:(NSEvent*)event
{
	unichar c=[[event charactersIgnoringModifiers] characterAtIndex:0];
	switch(c)
	{
	// [Esc] exits FullScreen mode.
	case 27:
	case 'Q':
	case 'q':
		fullscreen=NO;
		break;
	// [R] resets the scene -- not textures
	case 'r':
	case 'R':
		[self reset];
		break;
	// [W] toggles wireframe rendering
	case 'w':
	case 'W':
		wireframe=!wireframe;
		break;
	// [M] toggles mirroring
	case 'm':
	case 'M':
		mirror=!mirror;
		break;
	// [T] toggles text
	case 't':
	case 'T':
		text=!text;
		break;
	// [H] toggles help
	case 'h':
	case 'H':
		help=!help;
		break;
	// [ ] toggles animation
	// [A] toggles animation
	case ' ':
	case 'a':
	case 'A':
		rotation.x+=animationTime;
		rotation.y+=animationTime;
		rotation.z+=animationTime;
		animationTime=0.0;
		animating=!animating;
		break;
	default:
		break;
	}
}

- (void)mouseDown:(NSEvent*)theEvent
{
	oldPoint=[theEvent locationInWindow];
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
	oldPoint=[theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
	NSPoint point=[theEvent locationInWindow];
	if([theEvent modifierFlags]&NSShiftKeyMask)
	{
		scale.x+=(point.y-oldPoint.y)/128.0;
		scale.y+=(point.y-oldPoint.y)/128.0;
		scale.z+=(point.y-oldPoint.y)/128.0;
		scale.x=MAXOF2(scale.x,0);
		scale.y=MAXOF2(scale.y,0);
		scale.z=MAXOF2(scale.z,0);
	}
	else
	{
		translation.x+=(point.x-oldPoint.x)/1024.0;
		translation.y+=(point.y-oldPoint.y)/1024.0;
	}
	oldPoint=point;
}

- (void)rightMouseDragged:(NSEvent*)theEvent
{
	NSPoint point=[theEvent locationInWindow];
	if([theEvent modifierFlags]&NSShiftKeyMask)
	{
		rotation.x-=(point.y-oldPoint.y);
		rotation.y+=(point.x-oldPoint.x);
	}
	else
	{
		rotation.z-=(point.x-oldPoint.x);
	}
	oldPoint=point;
}

@end
