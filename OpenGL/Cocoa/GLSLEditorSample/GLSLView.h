// GLSLView

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

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import <Cocoa/Cocoa.h>

typedef struct {
   GLdouble x,y,z;
} recVec;

typedef struct {
	recVec viewPos; // View position
	recVec viewDir; // View direction vector
	recVec viewUp; // View up direction
	recVec rotPoint; // Point to rotate about
	GLdouble aperture; // pContextInfo->camera aperture
	GLint viewWidth, viewHeight; // current window/screen height and width
} recCamera;

@class GLSLController;

@interface GLSLView : NSOpenGLView
{
    IBOutlet GLSLController * controller; // the app controller which contains the GL view (easy access)
	
	bool fGLInit;
	bool fSoftwareRenderer;
	bool glslSupport; // does current renderer support GLSL?
	bool fChangingRenderers;
	
	NSTimer* timer;
 
    bool fAnimate;
    bool fShader;
    int drawObject;
	
    GLint vertexGPUProcessing;
    GLint fragmentGPUProcessing;

	CFAbsoluteTime time;

	// spin
	GLfloat rRot [3];
	GLfloat rVel [3];
	GLfloat rAccel [3];
	
	// camera handling
	recCamera camera;
	GLfloat worldRotation [4];
	GLfloat objectRotation [4];
	GLfloat shapeSize;

	GLUquadric * pSphere;
	GLuint sphereList;
	GLuint torusList;
	GLuint planeList;

	
	NSString * _imagePath; // path for saving...
	
	GLint multiTexUnitCount;
	GLuint *multiTexNames;
	int *multiTexActiveFlags;
	GLenum *multiTexTargets;
	NSImage **multiTexImages;
	NSSize texSize;

	//saved partial state
	bool fSetState;
	GLboolean lighting;
	GLboolean lightsOn[8];
	GLfloat lightParams[8][9][4];
	GLboolean fogging;
	GLfloat fogParams[4][4];

	IBOutlet NSTextField *colorRText;
	IBOutlet NSTextField *colorGText;
	IBOutlet NSTextField *colorBText;
	IBOutlet NSTextField *colorAText;
}

+ (NSOpenGLPixelFormat*) basicPixelFormat;
+ (NSOpenGLPixelFormat*) floatPixelFormat;


- (void) planeWithSize:(NSSize)size withDivisions:(int)divisions;
- (void) sphereWithRadius:(float)r withDivisions:(int)n;
- (void) doughnutWithInnerRadius:(float)r withOuterRadius:(float)R withDivisions:(int)nsides withRings:(int)rings;
- (void) drawShape:(GLint)shape;

-(void) setFloatRenderer:(int)value;
-(void) animate:(int)value;
-(void) useShader:(GLhandleARB)program;
-(BOOL) usingShader;
-(void) object:(int)value;
-(BOOL) usingSoftwareRenderer;
-(BOOL) supportsGLSL;


- (void) updateProjection;
- (void) updateModelView;
- (void) resizeGL;
- (void) resetCamera;

- (void) updateObjectRotationForTimeDelta:(CFAbsoluteTime)deltaTime;
- (void) animationTimer:(NSTimer *)timer;

- (void) useImageAsTexture:(NSImage *)textureImage forUnit:(int)unit withTarget:(GLenum)target;

- (void) keyDown:(NSEvent *)theEvent;

- (void) mouseMoved:(NSEvent *)theEvent;
- (void) mouseDown:(NSEvent *)theEvent;
- (void) rightMouseDown:(NSEvent *)theEvent;
- (void) otherMouseDown:(NSEvent *)theEvent;
- (void) mouseUp:(NSEvent *)theEvent;
- (void) rightMouseUp:(NSEvent *)theEvent;
- (void) otherMouseUp:(NSEvent *)theEvent;
- (void) mouseDragged:(NSEvent *)theEvent;
- (void) scrollWheel:(NSEvent *)theEvent;
- (void) rightMouseDragged:(NSEvent *)theEvent;
- (void) otherMouseDragged:(NSEvent *)theEvent;

- (void) drawRect:(NSRect)rect;

- (void)rebuildObjects;
- (void) prepareOpenGL;
- (void) update;		// moved or resized

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (void) checkGLSLSupport;
- (void) setFloatRenderer: (int) state;
- (id) initWithFrame: (NSRect) frameRect;
- (void) awakeFromNib;


@end
