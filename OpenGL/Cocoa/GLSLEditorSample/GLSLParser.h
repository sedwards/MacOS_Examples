// GLSLEditorExample

/*

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

  Copyright (c) 2003-2006 Apple Computer, Inc., All rights reserved.
  
*/

#import <Cocoa/Cocoa.h>

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "uniformValue.h"

@class GLSLController;

@interface GLSLParser : NSObject
{
    IBOutlet GLSLController * controller; // the app controller which contains the GL view (easy access)
	
	BOOL mAutoLink;
	GLhandleARB program;
	GLint status; // link status
	GLint valid; // validate status
	GLcharARB * log;
	GLint logLength;
	
	int currentUniformIndex;
	GLsizei currLength;
	GLint currSize;
	GLenum currType;
	GLcharARB *currName;
	int currLocation;

    NSMutableDictionary * stanStringAttrib;
    NSMutableDictionary * errorStringAttrib;
}

- (void)setLinkResults; // a shader was compiled successfully
//- (void)setUnformControls; // set up controls for settign uniforms
- (void) setCurrentUniform:(int)index; // sets current uniform select by menu
- (void) setUniformInt:(uniformValue *)value; // value for current uniform
- (void) setUniformFloat:(uniformValue *)value; // value for current uniform

// calls to the following from a document must ensure the GL context is setup and made currently
- (GLhandleARB)getShaderHandleFor:(GLenum)shaderType; // get shader handle from parser (this will be attached to program object)
- (void)attachShaderHandle:(GLhandleARB)handle; // attaches a shader handle to the program
- (void)detachShaderHandle:(GLhandleARB)handle; // detaches a shader handle to the program
- (void)releaseShaderHandle:(GLhandleARB)shaderHandle; // this will allow the parser to destory the handle
- (void)successfulCompile; // a shader was compiled successfully (should be notification)

- (void)link;
- (GLhandleARB)getLinkedProgram; // returns the program if it is successfully linked

-(BOOL) checkReportOpenGLError: (NSString *) function;

- (void) invalidateProgram; // called on renderer change to 

@end
