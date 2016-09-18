//
//  GLImageSplitterView.m
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

#import <OpenGL/gl.h>

#import "GLImageSplitterView.h"

//This class is a subview of SplitterBox -- one of these exists per display and is resized by the SplitterBox

@implementation GLImageSplitterView

/*
	Override NSView's initWithFrame: to specify our pixel format:
	
	Note: initWithFrame is called only if a "Custom View" is used in Interface BBuilder 
	and the custom class is a subclass of NSView. For more information on resource loading
	see: developer.apple.com (ADC Home > Documentation > Cocoa > Resource Management > Loading Resources)
*/	

- (id)initWithFrame:(NSRect)frameRect display:(CGDirectDisplayID)displayID scene:(Scene*)newScene
{
	NSOpenGLPixelFormatAttribute attribs[] = 
	{
		NSOpenGLPFAWindow,

		NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(displayID),

		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 8,
		NSOpenGLPFADepthSize, 24,

		NSOpenGLPFANoRecovery,
		//NSOpenGLPFAAccelerated,
		0
	};

	NSOpenGLPixelFormat* fmt=[[NSOpenGLPixelFormat alloc] initWithAttributes:attribs]; 

	//base init
	self=[super initWithFrame:frameRect pixelFormat:fmt];
	if(self)
	{
		//turn on vsync
		GLint newSwapInterval=1;
		CGLSetParameter([[self openGLContext] CGLContextObj],kCGLCPSwapInterval,&newSwapInterval);

		textureTiler=[[TextureTiler alloc] init];

		scene=newScene;
		[scene retain];

		NSFont* font=[NSFont fontWithName:@"Helvetica" size:12.0];
		stanStringAttrib=[[NSMutableDictionary dictionary] retain];
		[stanStringAttrib setObject:font forKey:NSFontAttributeName];
		[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		[font release];

		helpString=[[StringTexture alloc] initWithString:[NSString stringWithFormat:@"'H' : Help   'M' : Mirror   'T' : Text   'A' or Space : Animate\n'W' : Wireframe   'R' : Reset   'Q' or Esc : Exit Fullscreen"] withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.0f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.3f green:0.8f blue:0.3f alpha:0.8f]];
		textString=[[StringTexture alloc] initWithString:[NSString stringWithFormat:@"hopefully you will not see this string...\nplease ignore this"] withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.0f alpha:0.5f] withBorderColor:[NSColor colorWithDeviceRed:0.3f green:0.8f blue:0.3f alpha:0.8f]];
	}
	return self;
}

//TODO use '- (void)prepareOpenGL' to share contexts between renderers

- (void)dealloc
{
	//set current context to context that created these textures
	[[self openGLContext] makeCurrentContext];

	[stanStringAttrib release];
	[textureTiler release];
	[helpString release];
	[textString release];
	[scene release];
	[super dealloc];
}

//be safe with these
- (TextureTiler*)textureTiler
{
	return textureTiler;
}

- (StringTexture*)helpString
{
	return helpString;
}
- (StringTexture*)textString
{
	return textString;
}

- (void)updateTextString:(NSRect)bounds virtualBounds:(NSRect)virtualBounds mainBounds:(NSRect)mainBounds
{
	[textString setString:[NSString stringWithFormat:@"%s:%s\nBounds ((%g %g) (%g %g))\nVirtualBounds ((%g %g) (%g %g))\nMainBounds ((%g %g) (%g %g))",glGetString(GL_RENDERER),glGetString(GL_VERSION),bounds.origin.x,bounds.origin.y,bounds.size.width,bounds.size.height,virtualBounds.origin.x,virtualBounds.origin.y,virtualBounds.size.width,virtualBounds.size.height,mainBounds.origin.x,mainBounds.origin.y,mainBounds.size.width,mainBounds.size.height] withAttributes:stanStringAttrib];
}

//Draw the scene within the current display ONLY
- (void)drawRect:(NSRect)rect
{
	//in windowed mode the virtual bounds are the real bounds
	[scene setViewportRect:[self frame] virtualBounds:[self frame] mainBounds:[[self superview] bounds]];
	[self updateTextString:[self frame] virtualBounds:[self frame] mainBounds:[[self superview] bounds]];
	[scene renderWithTextureTiler:textureTiler helpString:helpString textString:textString];

	[[self openGLContext] flushBuffer];
}

- (BOOL)isOpaque
{
	//we want the superview to control the drawing/updating of these views
	return NO;
}

@end
