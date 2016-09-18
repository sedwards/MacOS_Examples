//
//  SplitterBox.m
//  GLImageSplitter
//
//  Created on 3/1/06.
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

//This class handles fullscreen and windowed splitting across multiple displays

//NOTE: This does not handle display/renderer changes
//You can rearrange and resize them but not add/remove/switch renderer
//TODO Use DMRegisterExtendedNotifyProc to handle these cases correctly
//TODO override maximize/zoom so that the window fills all screens... not so easy...

#import <OpenGL/OpenGL.h>
#import "SplitterBox.h"

#include "VariousUtilities.h"

@implementation SplitterBox

//Intersect this view with the specified display and return only the rect that is inside this display
//Should be HighDPI safe
- (NSRect)getSubFrameForDisplay:(NSRect)displayRect
{
	NSRect globalFrame=[self convertRect:[self bounds] toView:nil];
	globalFrame.origin=[[self window] convertBaseToScreen:globalFrame.origin];
	
	NSRect sectFrame=NSIntersectionRect(globalFrame,displayRect);
	
	sectFrame.origin=[[self window] convertScreenToBase:sectFrame.origin];
	
	sectFrame=[self convertRect:sectFrame fromView:nil];
	
	return sectFrame;
}

- (id)initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if(self)
	{
//TODO register for Display Manager changes and update the views list accordingly
//DMRegisterExtendedNotifyProc
		displayData=[[DisplayData alloc] init];
		scene=[[Scene alloc] init];

		views[0]=nil;
		NSArray* displays=[NSScreen screens];
		int onDisplay;
		for(onDisplay=0;onDisplay<[displays count];onDisplay++)
		{
			views[onDisplay]=[[GLImageSplitterView alloc] initWithFrame:[self getSubFrameForDisplay:[[displays objectAtIndex:onDisplay] frame]] display:[[[[displays objectAtIndex:onDisplay] deviceDescription] objectForKey:@"NSScreenNumber"] pointerValue] scene:scene];
			[self addSubview:views[onDisplay]];
		}
	}
	return self;
}

- (void)dealloc
{
	[displayData release];
	[scene release];
    [super dealloc];
}

- (void) drawRect:(NSRect)rect
{
	//this work can be done in different places to optimize drawing and updates to the minimum necessary

	NSArray* displays=[NSScreen screens];
	int onDisplay;
	for(onDisplay=0;onDisplay<[displays count];onDisplay++)
	{
		NSRect subRect=[self getSubFrameForDisplay:[[displays objectAtIndex:onDisplay] frame]];
		[views[onDisplay] setFrame:subRect];
		[views[onDisplay] setNeedsDisplay:YES];
	}
}

- (void)reshape
{
	// Delegate to our scene object to update for a change in the view size.
	//Simply force a redisplay -- not very optimal
	[self setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
	[tileSize setIntValue:512];
	[displaysConfig setDataSource:displayData];
	[self resetDisplays:displaysConfig];
}

- (BOOL)acceptsFirstResponder
{
	// We want this view to be able to receive key events.
	return YES;
}

- (void)keyDown:(NSEvent*)theEvent
{
	[scene keyDown:theEvent];
	[self updateAnimationTimers:[scene animating]];
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent*)theEvent
{
	[scene mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
	[scene rightMouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
	if([theEvent modifierFlags]&NSControlKeyMask)
	{
		//fake the right mouse button... this is rather annoying...
		[scene rightMouseDragged:theEvent];
	}
	else
	{
		[scene mouseDragged:theEvent];
	}
	[self setNeedsDisplay:YES];
}

- (void)rightMouseDragged:(NSEvent*)theEvent
{
	[scene rightMouseDragged:theEvent];
	[self setNeedsDisplay:YES];
}

- (void)textureChanged
{
	NSArray* displays=[NSScreen screens];
	int onDisplay;
	for(onDisplay=0;onDisplay<[displays count];onDisplay++)
	{
		//this is not very optimal...
		[[views[onDisplay] openGLContext] makeCurrentContext];
		[[views[onDisplay] textureTiler] textureChanged:[imageView image] tileSize:[tileSize intValue] AGPTexturing:[AGPTexturingCheckBox intValue] borders:[bordersCheckBox intValue]];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction)AGPTexturingChanged:(id)sender
{
	[self textureChanged];
}

- (IBAction)bordersChanged:(id)sender
{
	[self textureChanged];
}

- (IBAction)textureImageDropped:(id)sender
{
	[self textureChanged];
}

- (IBAction)tileSizeChanged:(id)sender
{
	[self textureChanged];
}

- (IBAction)fullScreen:(id)sender
{
	NSOpenGLContext* fullScreenContext[MAX_DISPLAYS];
	GLint oldSwapInterval[MAX_DISPLAYS];

	//init
	// Take control of all the displays where we're about to go FullScreen.
	NSArray* displays=[NSScreen screens];
	CGDisplayErr error=CGCaptureAllDisplays();
	if(error!=CGDisplayNoErr)
	{
		NSLog(@"Failed to capture all displays");
		return;
	}
	//turn off the animation timer -- dont want it firing for no reason
	[self updateAnimationTimers:FALSE];

	int onDisplay;
	for(onDisplay=0;onDisplay<[displays count]&!error;onDisplay++)
	{
		// Pixel Format Attributes for the FullScreen NSOpenGLContext
		NSOpenGLPixelFormatAttribute attrs[] =
		{
			// Specify that we want a full-screen OpenGL context.
			NSOpenGLPFAFullScreen,

			// We may be on a multi-display system (and each screen may be driven by a different renderer), so we need to specify which screen we want to take over.  For this demo, we'll specify the main screen.
			NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask([[[[displays objectAtIndex:onDisplay] deviceDescription] objectForKey:@"NSScreenNumber"] pointerValue]),

			// Attributes Common to FullScreen and non-FullScreen
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAColorSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFADepthSize, 24,

			NSOpenGLPFANoRecovery,
			//NSOpenGLPFAAccelerated,
			0
		};

		// Create the FullScreen NSOpenGLContext with the attributes listed above.
		NSOpenGLPixelFormat* pixelFormat=[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

		// Just as a diagnostic, report the renderer ID that this pixel format binds to.  CGLRenderers.h contains a list of known renderers and their corresponding RendererID codes.
		long rendererID;
		[pixelFormat getValues:&rendererID forAttribute:NSOpenGLPFARendererID forVirtualScreen:0];

		// Create an NSOpenGLContext with the FullScreen pixel format.  By specifying the non-FullScreen contexts as our "shareContexts", we automatically inherit all of the textures, display lists, and other OpenGL objects it has defined.
		fullScreenContext[onDisplay]=[[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:[views[onDisplay] openGLContext]];
		[pixelFormat release];
		pixelFormat=nil;

		if(fullScreenContext[onDisplay]==nil)
		{
			NSLog(@"Failed to create fullScreenContext");
			error=1;
			break;
		}

		// Enter FullScreen mode and make our FullScreen context the active context for OpenGL commands.
		[fullScreenContext[onDisplay] setFullScreen];
		[fullScreenContext[onDisplay] makeCurrentContext];

		// Save the current swap interval so we can restore it later, and then set the new swap interval to lock us to the display's refresh rate.
		CGLContextObj cglContext=CGLGetCurrentContext();
		CGLGetParameter(cglContext,kCGLCPSwapInterval,&oldSwapInterval[onDisplay]);
		GLint newSwapInterval=1;
		CGLSetParameter(cglContext,kCGLCPSwapInterval,&newSwapInterval);
	}

	//Main Event Loop
	// Now that we've got the screen, we enter a loop in which we alternately process input events and computer and render the next frame of our animation.  The shift here is from a model in which we passively receive events handed to us by the AppKit to one in which we are actively driving event processing.
	[scene setFullscreen:YES];
	while([scene fullscreen]&&!error)
	{
		NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];

		// Check for and process input events.
		NSEvent *event;
		while(event=[NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES])
		{
			switch([event type])
			{
			case NSLeftMouseDown:
				if([event modifierFlags]&NSControlKeyMask)
				{
					//fake the right mouse button... this is rather annoying...
					[scene rightMouseDown:event];
				}
				else
				{
					[scene mouseDown:event];
				}
				break;
			case NSLeftMouseUp:
				if([event modifierFlags]&NSControlKeyMask)
				{
					//fake the right mouse button... this is rather annoying...
					[scene rightMouseUp:event];
				}
				else
				{
					[scene mouseUp:event];
				}
				break;
			case NSLeftMouseDragged:
				if([event modifierFlags]&NSControlKeyMask)
				{
					//fake the right mouse button... this is rather annoying...
					[scene rightMouseDragged:event];
				}
				else
				{
					[scene mouseDragged:event];
				}
				break;
			case NSRightMouseDown:
				[scene rightMouseDown:event];
				break;
			case NSRightMouseUp:
				[scene rightMouseUp:event];
				break;
			case NSRightMouseDragged:
				[scene rightMouseDragged:event];
				break;
			case NSKeyDown:
				[scene keyDown:event];
				break;
			default:
				break;
			}
		}

		//find min origin, max size
		NSRect mainBounds=[displayData displays][0];
		//int onDisplay;
		for(onDisplay=1;onDisplay<[displays count]&!error;onDisplay++)
		{
			NSRect virtualBounds=[displayData displays][onDisplay];
			mainBounds=NSUnionRect(mainBounds,virtualBounds);
		}

		// Render a frame, and swap the front and back buffers.
		//Render Loop
		//int onDisplay;
		for(onDisplay=0;onDisplay<[displays count]&!error;onDisplay++)
		{
			[fullScreenContext[onDisplay] makeCurrentContext];

			NSRect bounds=[[displays objectAtIndex:onDisplay] frame];
			NSRect virtualBounds=[displayData displays][onDisplay];

			// Render a frame, and swap the front and back buffers.
			// Tell the scene the dimensions of the area it's going to render to, so it can set up an appropriate viewport and viewing transformation.
			[scene setViewportRect:bounds virtualBounds:virtualBounds mainBounds:mainBounds];
			[views[onDisplay] updateTextString:bounds virtualBounds:virtualBounds mainBounds:mainBounds];

			[scene renderWithTextureTiler:[views[onDisplay] textureTiler] helpString:[views[onDisplay] helpString] textString:[views[onDisplay] textString]];
			[fullScreenContext[onDisplay] flushBuffer];
		}

		// Clean up any autoreleased objects that were created this time through the loop.
		[pool release];
	}

	//Cleanup
	//int onDisplay;
	for(onDisplay=0;onDisplay<[displays count]&!error;onDisplay++)
	{
		if(fullScreenContext[onDisplay]!=nil)
		{
			[fullScreenContext[onDisplay] makeCurrentContext];

			// Clear the front and back framebuffers before switching out of FullScreen mode.  (This is not strictly necessary, but avoids an untidy flash of garbage.)
			glClearColor(0.0,0.0,0.0,0.0);
			glClear(GL_COLOR_BUFFER_BIT);
			[fullScreenContext[onDisplay] flushBuffer];
			glClear(GL_COLOR_BUFFER_BIT);
			[fullScreenContext[onDisplay] flushBuffer];

			// Restore the previously set swap interval.
			CGLContextObj cglContext=CGLGetCurrentContext();
			CGLSetParameter(cglContext,kCGLCPSwapInterval,&oldSwapInterval[onDisplay]);

			// Exit fullscreen mode and release our FullScreen NSOpenGLContext.
			[NSOpenGLContext clearCurrentContext];

			[fullScreenContext[onDisplay] clearDrawable];
			[fullScreenContext[onDisplay] release];
			fullScreenContext[onDisplay]=nil;
		}
	}
	// Release control of the display.
	CGReleaseAllDisplays();
	// Mark our view as needing drawing.  (The animation has advanced while we were in FullScreen mode, so its current contents are stale.)
	[self setNeedsDisplay:YES];
	//turn back on the animation timer
	[self updateAnimationTimers:[scene animating]];
}

- (IBAction)resetDisplays:(id)sender
{
	[displayData reset];
	[displaysConfig reloadData];
}

-(BOOL)isOpaque
{
	//small speedup
	return YES;
}

- (void)updateAnimationTimers:(BOOL)animating
{
	//if we hit this we are not in fullscreen
	if(animating)
	{
		//make timer
		if(animationTimer==nil)
		{
			animationTimer=[[NSTimer scheduledTimerWithTimeInterval:0.017 target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES] retain];
		}
	}
	else
	{
		//free timer
		if(animationTimer!=nil)
		{
			[animationTimer invalidate];
			[animationTimer release];
			animationTimer=nil;
		}
	}
}

- (void)animationTimerFired:(NSTimer*)timer
{
	[self setNeedsDisplay:YES];
}

//TODO override windowDidMove so that the window can be moved offscreen and not messup

@end
