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

  Copyright (c) 2004-2005 Apple Computer, Inc., All rights reserved.
  
*/

#import "GLSLView.h"
#import "GLSLController.h"
#include "trackball.h"
#include "teapot.h"
#include <OpenGL/CGLRenderers.h>
#include <OpenGL/OpenGL.h>
#import <OpenGL/CGLTypes.h>

recVec gOrigin = {0.0, 0.0, 0.0};

#define kMaxTextureUnits 8


// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE;
GLboolean gPan = GL_FALSE;
GLboolean gTrackball = GL_FALSE;
GLSLView * gTrackingViewInfo = NULL;

// ==================================

#pragma mark ---- Utilities ----

static CFAbsoluteTime gStartTime = 0.0f;

// set app start time
static void setStartTime (void)
{	
	gStartTime = CFAbsoluteTimeGetCurrent ();
}

// ---------------------------------

// return float elpased time in seconds since app start
//static CFAbsoluteTime getElapsedTime (void)
//{	
//	return CFAbsoluteTimeGetCurrent () - gStartTime;
//}

#pragma mark ---- Error Reporting ----

// error reporting as both window message and debugger string
#if 0
static void reportError (char * strError)
{
	printf("%s\n", strError);
}
#endif

static void reportErrorWithFileLine (char *file, int checkLine, char * strError)
{
	printf("GL error at %s:%d: %s\n", file, checkLine, strError);
}

// ---------------------------------

// if error dump gl errors to debugger string, return error
#define glReportError() glReportErrorWithFileLine(__FILE__, __LINE__)

static GLenum glReportErrorWithFileLine (char *file, int line)
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err)
		reportErrorWithFileLine (file, line, (char *) gluErrorString (err));
	return err;
}

// ===================================

// ensures Cocoa does not do funky things with my un-accelerated back buffer
@interface NSSurface
- (void)_disposeSurface;
@end

@implementation NSSurface(Test)

- (void)_windowWillGoAway: (id)p
{
// do nothing to override default behavior
}

@end

// ===================================

@implementation GLSLView

// pixel format definition
+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, // 32 bit depth buffer
        (NSOpenGLPixelFormatAttribute)nil
    };
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

// ---------------------------------

// pixel format definition
+ (NSOpenGLPixelFormat*) floatPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, // 32 bit depth buffer
        NSOpenGLPFARendererID, kCGLRendererGenericFloatID, // software renderer
        (NSOpenGLPixelFormatAttribute)nil
    };
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

// ---------------------------------

// update the projection matrix based on camera and view info
- (void) updateProjection
{
	GLdouble near, far;
	GLdouble aspect = camera.viewWidth / (float) camera.viewHeight;
	[[self openGLContext] makeCurrentContext];
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (near < 0.1)
		near = 0.1;
	if (aspect > 1.0f) // do not adjust for narrow window
		gluPerspective (camera.aperture, aspect, near, far);
	else // adjust fovy for narrow windows
		gluPerspective (camera.aperture / aspect, aspect, near, far);
}

// ---------------------------------

// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
	// move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
			
	// if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);
	else {
	}
	// accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
	// object itself rotating applied after camera rotation
	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
	rRot[0] = 0.0f; // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
	rRot[1] = 0.0f;
	rRot[2] = 0.0f;
}

// ---------------------------------

// handles resizing of GL need context update and if the window dimensions change, a
// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	
	// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) {
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
	}
}

// ---------------------------------

// move camera in z axis
-(void)mouseDolly: (NSPoint) location
{
	GLfloat dolly = (gDollyPanStartPoint[1] -location.y) * -camera.viewPos.z / 300.0f;
	camera.viewPos.z += dolly;
	if (camera.viewPos.z == 0.0) // do not let z = 0.0
		camera.viewPos.z = 0.0001;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}
	
// ---------------------------------
	
// move camera in x/y plane
- (void)mousePan: (NSPoint) location
{
	GLfloat panX = (gDollyPanStartPoint[0] - location.x) / (900.0f / -camera.viewPos.z);
	GLfloat panY = (gDollyPanStartPoint[1] - location.y) / (900.0f / -camera.viewPos.z);
	camera.viewPos.x -= panX;
	camera.viewPos.y -= panY;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

// ---------------------------------

// sets the camera data to initial conditions
- (void) resetCamera
{
   camera.aperture = 40;
   camera.rotPoint = gOrigin;

   camera.viewPos.x = 0.0;
   camera.viewPos.y = 0.0;
   camera.viewPos.z = -10.0;
   camera.viewDir.x = -camera.viewPos.x; 
   camera.viewDir.y = -camera.viewPos.y; 
   camera.viewDir.z = -camera.viewPos.z;

   camera.viewUp.x = 0;  
   camera.viewUp.y = 1; 
   camera.viewUp.z = 0;
}

// ---------------------------------

// given a delta time in seconds and current rotation accel, velocity and position, update overall object rotation
- (void) updateObjectRotationForTimeDelta:(CFAbsoluteTime)deltaTime
{
	// update rotation based on vel and accel
	float rotation[4] = {0.0f, 0.0f, 0.0f, 0.0f};
	GLfloat fVMax = 2.0;
	short i;
	// do velocities
	for (i = 0; i < 3; i++) {
		rVel[i] += rAccel[i] * deltaTime * 30.0;
		
		if (rVel[i] > fVMax) {
			rAccel[i] *= -1.0;
			rVel[i] = fVMax;
		} else if (rVel[i] < -fVMax) {
			rAccel[i] *= -1.0;
			rVel[i] = -fVMax;
		}
		
		rRot[i] += rVel[i] * deltaTime * 30.0;
		
		while (rRot[i] > 360.0)
			rRot[i] -= 360.0;
		while (rRot[i] < -360.0)
			rRot[i] += 360.0;
	}
	rotation[0] = rRot[0];
	rotation[1] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = rRot[1];
	rotation[1] = 0.0f; rotation[2] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = rRot[2];
	rotation[2] = 0.0f; rotation[3] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
}

// ---------------------------------

// per-window timer function, basic time based animation preformed here
- (void)animationTimer:(NSTimer *)timer
{
	BOOL shouldDraw = NO;
	if (fAnimate) {
		CFTimeInterval deltaTime = CFAbsoluteTimeGetCurrent () - time;
			
		if (deltaTime > 10.0) // skip pauses
			return;
		else {
			// if we are not rotating with trackball in this window
			if (!gTrackball || (gTrackingViewInfo != self)) {
				[self updateObjectRotationForTimeDelta: deltaTime]; // update object rotation
			}
			shouldDraw = YES; // force redraw
		}
	}
	time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
	if (YES == shouldDraw) 
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
}

// ---------------------------------

- (void) useImageAsTexture:(NSImage *)textureImage forUnit:(int)unit withTarget:(GLenum)target
{
	NSBitmapImageRep * bitmap = nil;
    int samplesPerPixel = 0;
	
	if (nil == multiTexImages) {
		NSLog (@"-useImageAsTexture: OpenGL not initialized properly");
		return;
	}
	if (unit >= multiTexUnitCount)
		return;
		
	// save image reference
	multiTexImages[unit] = textureImage;
	if (textureImage) {
		[textureImage retain];

		[textureImage lockFocus];
		bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
				   NSMakeRect (0.0f, 0.0f, [textureImage size].width, [textureImage size].height)];
		[textureImage unlockFocus];
	}
	glActiveTexture(GL_TEXTURE0 + unit);
	glReportError ();
	if (multiTexActiveFlags[unit]) // delete old texture
	{
		glEnable (multiTexTargets[unit]);
		glDeleteTextures(1, &multiTexNames[unit]);
		glReportError ();
		glDisable (multiTexTargets[unit]);
		multiTexActiveFlags[unit] = 0;
	}
	if (textureImage) {
		multiTexTargets[unit] = target; // enable this one
		glEnable (multiTexTargets[unit]);
		multiTexActiveFlags[unit] = 1;
		glGenTextures(1, &multiTexNames[unit]);
		glReportError ();
		glBindTexture(multiTexTargets[unit], multiTexNames[unit]);
		glReportError ();
		// Set proper unpacking row length for bitmap
		glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap pixelsWide]);
		glReportError ();
		// Set byte aligned unpacking (needed for 3 byte per pixel bitmaps)
		glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
		glReportError ();
		// Non-mipmap filtering (redundant for texture_rectangle)
		glTexParameteri(multiTexTargets[unit], 
						GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glReportError ();
		samplesPerPixel = [bitmap samplesPerPixel];

		// Non-planar, RGB 24 bit bitmap, or RGBA 32 bit bitmap
		if(![bitmap isPlanar] && 
		   (samplesPerPixel == 3 || samplesPerPixel == 4)) { 
			 glTexImage2D(multiTexTargets[unit], 
						  0, 
						  samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
						  [bitmap pixelsWide], 
						  [bitmap pixelsHigh], 
						  0, 
						  samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
						  GL_UNSIGNED_BYTE, 
						  [bitmap bitmapData]);
			glReportError ();
		} else {
		/*
			Error condition...
			The above code handles 2 cases (24 bit RGB and 32 bit RGBA),
			it is possible to support other bitmap formats if desired.
			
			So we'll log out some useful information.
		*/
			NSLog (@"-useImageAsTexture: Unsupported bitmap data format: isPlanar:%d, samplesPerPixel:%d, bitsPerPixel:%d, bytesPerRow:%d, bytesPerPlane:%d",
				[bitmap isPlanar], 
				[bitmap samplesPerPixel], 
				[bitmap bitsPerPixel], 
				[bitmap bytesPerRow], 
				[bitmap bytesPerPlane]);
		}
		[bitmap release];
		glDisable (multiTexTargets[unit]);
	}
	// rebuild display lists...
	[self rebuildObjects];
}

// ---------------------------------

- (void) planeWithSize:(NSSize)size withDivisions:(int)divisions
{
	int i, j, k;
	GLfloat xTex, xTex1, yTex;
	GLfloat xDelta = size.width / (float)divisions, yDelta = size.height / (float)divisions;
	GLfloat x1, x = -size.width * 0.5f; 
	GLfloat y1, y = -size.height * 0.5f - yDelta; 
	GLfloat xScale, yScale;
	for (i = divisions - 1; i >= 0; i--) {
		x1 = x + xDelta;
		y = -size.height * 0.5f;
		xTex = (GLfloat)i / (GLfloat) divisions;
		xTex1 = (GLfloat)(i + 1) / (GLfloat) divisions;
		glBegin(GL_QUAD_STRIP);
			for (j = divisions; j >= 0; j--) {
				y1 = y + yDelta;
				yTex = (GLfloat)j / (GLfloat) divisions;

				glNormal3f(0.0f, 0.0f, -1.0f);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex * xScale, yTex * yScale);
					}
				}
				glVertex2f(x1, y);
				
				glNormal3f(0.0f, 0.0f, -1.0f);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex1 * xScale, yTex * yScale);
					}
				}
				glVertex2f(x, y);

				y = y1;
			}
		glEnd();
		x = x1;
	}
}

// ---------------------------------

- (void) sphereWithRadius:(float)r withDivisions:(int)n
{
	int i,j, k;
	double theta1,theta2,theta3;
	float e[3], p[3];
	GLfloat xTex, yTex, yTex1;
	GLfloat xScale, yScale;

	if (r < 0)
	  r = -r;
	if (n < 0)
	  n = -n;
	// too few divisions or too small draw as point
	if (n < 4 || r == 0) {
	  glBegin(GL_POINTS);
		glVertex3f(0.0f, 0.0f, 0.0f);
	  glEnd();
	  return;
	}

	for (j=0;j<n/2;j++) {
		theta1 = j * 2.0 * M_PI / n - M_PI_2;
		theta2 = (j + 1) * 2.0 * M_PI / n - M_PI_2;

		yTex = 2.0f * (j + 1) / (GLfloat)n;
		yTex1 = 2.0f * j / (GLfloat)n;

		glBegin(GL_TRIANGLE_STRIP);
			for (i=0;i<=n;i++) {
				theta3 = i * 2.0 * M_PI / n;

				e[0] = cos(theta2) * cos(theta3);
				e[1] = sin(theta2);
				e[2] = cos(theta2) * sin(theta3);
				p[0] = r * e[0];
				p[1] = r * e[1];
				p[2] = r * e[2];

				xTex = (GLfloat)i / (GLfloat) n;
				
				glNormal3f(e[0],e[1],e[2]);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex * xScale, yTex * yScale);
					}
				}
				glVertex3f(p[0],p[1],p[2]);

				e[0] = cos(theta1) * cos(theta3);
				e[1] = sin(theta1);
				e[2] = cos(theta1) * sin(theta3);
				p[0] = r * e[0];
				p[1] = r * e[1];
				p[2] = r * e[2];

				glNormal3f(e[0],e[1],e[2]);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex * xScale, yTex1 * yScale);
					}
				}
				glVertex3f(p[0],p[1],p[2]);
			}
		glEnd();
	}
}

// ---------------------------------

- (void) doughnutWithInnerRadius:(float)r withOuterRadius:(float)R withDivisions:(int)nsides withRings:(int)rings
{
	int i, j, k;
	GLfloat theta, phi, theta1;
	GLfloat cosTheta, sinTheta;
	GLfloat cosTheta1, sinTheta1;
	GLfloat ringDelta, sideDelta;
	GLfloat xTex, xTex1, yTex;
	GLfloat xScale, yScale;

	ringDelta = 2.0 * M_PI / (float)rings;
	sideDelta = 2.0 * M_PI / (float)nsides;

	theta = 0.0;
	cosTheta = 1.0;
	sinTheta = 0.0;
	for (i = rings - 1; i >= 0; i--) {
		theta1 = theta + ringDelta;
		cosTheta1 = cos(theta1);
		sinTheta1 = sin(theta1);
		xTex = (GLfloat)i / (GLfloat) rings;
		xTex1 = (GLfloat)(i + 1) / (GLfloat) rings;
		glBegin(GL_QUAD_STRIP);
			phi = 0.0;
			for (j = nsides; j >= 0; j--) {
				GLfloat cosPhi, sinPhi, dist;

				phi += sideDelta;
				cosPhi = cos(phi);
				sinPhi = sin(phi);
				dist = R + r * cosPhi;
				yTex = (GLfloat)j / (GLfloat) nsides;

				glNormal3f(cosTheta1 * cosPhi, -sinTheta1 * cosPhi, sinPhi);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex * xScale, yTex * yScale);
					}
				}
				glVertex3f(cosTheta1 * dist, -sinTheta1 * dist, r * sinPhi);

				glNormal3f(cosTheta * cosPhi, -sinTheta * cosPhi, sinPhi);
				for (k = 0; k < kMaxTextureUnits; k++) {
					if (multiTexActiveFlags[k]) {
						if (multiTexTargets[k] == GL_TEXTURE_2D) {
							xScale = 1.0;
							yScale = 1.0;
						} else {
							xScale = [multiTexImages[k] size].width;
							yScale = [multiTexImages[k] size].height;
						}
						glMultiTexCoord2f(GL_TEXTURE0 + k, xTex1 * xScale, yTex * yScale);
					}
				}
				glVertex3f(cosTheta * dist, -sinTheta * dist,  r * sinPhi);
			}
		glEnd();
		theta = theta1;
		cosTheta = cosTheta1;
		sinTheta = sinTheta1;
	}
}


// ---------------------------------

- (void) drawShape:(GLint)shape
{
	int unit;
	for (unit = 0; unit < multiTexUnitCount; unit++)
	{
		if (multiTexActiveFlags[unit])
		{
			glActiveTexture(GL_TEXTURE0 + unit);
			glEnable(multiTexTargets[unit]);
		}
	}
	glColor3f (1.0, 1.0, 1.0); 
	glReportError ();
	switch (shape) {
		case 0:
			glDisable(GL_CULL_FACE);
//			glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);
			glCallList (planeList);
			glReportError ();
			break;
		case 1:
			glDisable(GL_CULL_FACE);
//			glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);
			glCallList (sphereList);
			glReportError ();
			break;
		case 2:
			glDisable(GL_CULL_FACE);
//			glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);
			glCallList (torusList);
			glReportError ();
			break;
		case 3:
			glDisable(GL_CULL_FACE);
			glutSolidTeapot(2.0);
			glReportError ();
			break;
		case 4:
			glDisable(GL_CULL_FACE);
			glutWireTeapot(2.0);
			glReportError ();
			break;
	}
	glReportError ();
	for (unit = 0; unit < multiTexUnitCount; unit++)
	{
		glActiveTexture(GL_TEXTURE0 + unit);
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_TEXTURE_RECTANGLE_ARB);
	}
	glReportError ();
}

#pragma mark ---- UI Support ----

-(void) animate:(int)value
{
	fAnimate = (value == NSOnState);
}

-(void) useShader:(GLhandleARB)program
{	
	GLenum error;
	glUseProgramObjectARB (program); // use shader	
	error = glGetError();
	if (program && GL_NO_ERROR == error)
		fShader = true;
	else
		fShader = false;
	if (error)
		NSLog (@"-useShader: glUseProgramObjectARB error: %s", gluErrorString (error));
	[self setNeedsDisplay: YES];
}

-(BOOL) usingShader {
	return fShader;
}

-(void) object:(int)value
{
	drawObject = value;
	[self setNeedsDisplay: YES];
}

-(BOOL) usingSoftwareRenderer;
{
	return fSoftwareRenderer;
}

#pragma mark ---- Image Data Creation ----

- (void)copyPixelsTo: (NSBitmapImageRep *)bitmap sourceRect: (NSRect)srcRect baseView: (NSView *)bView
{
    NSRect rect = NSIntersectionRect([self bounds], srcRect);
    GLvoid * pixels = (GLvoid *) [bitmap bitmapData];
    NSPoint origin = [self convertPoint: rect.origin toView: bView];
    GLfloat zero = 0.0f;
   
    [self lockFocus];
    while(glGetError() != GL_NO_ERROR);
	glPushAttrib(GL_ALL_ATTRIB_BITS);
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
        glReadBuffer(GL_BACK);
        
        glDisable(GL_COLOR_TABLE);
        glDisable(GL_CONVOLUTION_1D);
        glDisable(GL_CONVOLUTION_2D);
        glDisable(GL_HISTOGRAM);
        glDisable(GL_MINMAX);
        glDisable(GL_POST_COLOR_MATRIX_COLOR_TABLE);
        glDisable(GL_POST_CONVOLUTION_COLOR_TABLE);
        glDisable(GL_SEPARABLE_2D);
        
        glPixelMapfv(GL_PIXEL_MAP_R_TO_R, 1, &zero);
        glPixelMapfv(GL_PIXEL_MAP_G_TO_G, 1, &zero);
        glPixelMapfv(GL_PIXEL_MAP_B_TO_B, 1, &zero);
        glPixelMapfv(GL_PIXEL_MAP_A_TO_A, 1, &zero);
        
        glPixelStorei(GL_PACK_SWAP_BYTES, 0);
        glPixelStorei(GL_PACK_LSB_FIRST, 0);
        glPixelStorei(GL_PACK_IMAGE_HEIGHT, 0);
        glPixelStoref(GL_PACK_ROW_LENGTH, NSWidth(srcRect)); 
        glPixelStoref(GL_PACK_SKIP_PIXELS, origin.x);
		glPixelStoref(GL_PACK_SKIP_ROWS, NSHeight(srcRect) - (origin.y + NSHeight(rect)));
        glPixelStorei(GL_PACK_SKIP_IMAGES, 0);
        
        glPixelTransferi(GL_MAP_COLOR, 0);
        glPixelTransferf(GL_RED_SCALE, 1.0f);
        glPixelTransferf(GL_RED_BIAS, 0.0f);
        glPixelTransferf(GL_GREEN_SCALE, 1.0f);
        glPixelTransferf(GL_GREEN_BIAS, 0.0f);
        glPixelTransferf(GL_BLUE_SCALE, 1.0f);
        glPixelTransferf(GL_BLUE_BIAS, 0.0f);
        glPixelTransferf(GL_ALPHA_SCALE, 1.0f);
        glPixelTransferf(GL_ALPHA_BIAS, 0.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_RED_SCALE, 1.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_RED_BIAS, 0.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_SCALE, 1.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_BIAS, 0.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_SCALE, 1.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_BIAS, 0.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_SCALE, 1.0f);
        glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_BIAS, 0.0f);
        
 
        glReadPixels((GLint) NSMinX(rect), (GLint) NSMinY(rect),
                    (GLsizei) NSWidth(rect), (GLsizei) NSHeight(rect),
                    GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, pixels);
        // Get rid of any error, in order to not mislead the rest of the app
	glPopClientAttrib();
	glPopAttrib();
    while(glGetError() != GL_NO_ERROR);
    [self unlockFocus];
}

// ---------------------------------

static void flipAndfixUpAlphaComponents(NSBitmapImageRep *imageRep)
{
        register unsigned char * sp = [imageRep bitmapData];
        register int bytesPerRow = [imageRep bytesPerRow];
        register int height = [imageRep pixelsHigh];
        register int width = [imageRep pixelsWide];
    
        while (height > 1) { // top half mirrored to bottom
            register unsigned int * pt = (unsigned int *) sp;
            register unsigned int * pb = (unsigned int *) (sp + (height - 1) * bytesPerRow) ;
            register int w = width;
            while (w-- > 0) {
                unsigned int tmp = *pt | 0x000000FF;
                *pt++ = *pb | 0x000000FF;
                *pb++ = tmp;
            }
            sp += bytesPerRow;
            height -= 2;
        }
        if (height) { // middle row
            register int w = width;
			register unsigned int * pt = (unsigned int *) sp;
            while (w-- > 0) 
                *pt++ |= 0x000000FF;
        }
}

// ---------------------------------

- (NSBitmapImageRep *)bitmapInsideRect: (NSRect)rect
{
   NSBitmapImageRep *	bitmap = nil;
   
   if(NSIsEmptyRect(rect))
        rect = [self bounds];
   
   if((bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                            pixelsWide: NSWidth(rect)
                                            pixelsHigh: NSHeight(rect)
                                            bitsPerSample: 8
                                            samplesPerPixel: 4
                                            hasAlpha: YES
                                            isPlanar: NO
                                            colorSpaceName: NSDeviceRGBColorSpace
                                            bytesPerRow: NSWidth(rect) * 4 // must set width...
                                            bitsPerPixel: 32] autorelease]) == nil) {
        return nil;
    }   
    [self copyPixelsTo:bitmap sourceRect:rect baseView:self];
    flipAndfixUpAlphaComponents(bitmap);
   
   return bitmap;
}

// ---------------------------------

- (NSImage *)imageWithTIFFInsideRect: (NSRect)rect
{
    NSBitmapImageRep * bitmap = nil;
    NSImage * tiffImage = nil;
   
    // Create an NSImage containing the actual window contents as a TIFF graphics
    if((tiffImage = [[[NSImage alloc] init] autorelease]) == nil)
        return nil;
    if((bitmap = [self bitmapInsideRect: rect]) == nil)
        return nil;
    
    [tiffImage addRepresentation: bitmap];
    [tiffImage lockFocusOnRepresentation: bitmap];
    [tiffImage unlockFocus];
    return tiffImage;
}

// ---------------------------------

- (NSData *)dataWithTIFFOfContentView
{
   NSImage * tiffImage = [self imageWithTIFFInsideRect: NSZeroRect];
   NSData * data = nil;
   
   if(tiffImage != nil) {
      data = [tiffImage TIFFRepresentation];
   }
   return data;
}

// ---------------------------------

- (NSData *)dataWithRTFDOfContentView
{
    static int generationCounter = 1;
    NSAttributedString * myString = nil;
    NSFileWrapper * myFileWrapper = nil;
    NSTextAttachment * myTextAttachment = nil;
    NSData * tiffData = [self dataWithTIFFOfContentView];
		
    // create file wrapper
    if((myFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: tiffData]) == nil)
        return nil;
    [myFileWrapper setPreferredFilename: [NSString stringWithFormat: @"GLSL Parser %d.tiff", generationCounter++]];
	
    // create the text attachment
    if((myTextAttachment = [[NSTextAttachment alloc] initWithFileWrapper: myFileWrapper]) == nil) {
        [myFileWrapper release];
        return nil;
    }
    [myFileWrapper release];
	
    // create the attributed string
    if((myString = [NSAttributedString attributedStringWithAttachment: myTextAttachment]) == nil) {
        [myTextAttachment release];
        return nil;
    }
    [myTextAttachment release];
		
    // return the flattend data
    return [myString RTFDFromRange: NSMakeRange(0, [myString length]) documentAttributes: nil];
}

// ---------------------------------

	/* Returns a data object containing the current contents of the receiving window */
- (NSData *)contentsAsDataOfType: (NSString *)pboardType
{
    NSData * data = nil;
     if ([pboardType isEqualToString: NSTIFFPboardType] == YES) {
        data = [self dataWithTIFFOfContentView];
    } else if ([pboardType isEqualToString: NSRTFDPboardType] == YES) {
        data = [self dataWithRTFDOfContentView];
    }
    return data;
}

#pragma mark ---- Printing and copying ----

static BOOL writeDataToFile(NSData *data, NSString *path, OSType hfsType)
{
    if([data writeToFile: path atomically: YES] == YES) {
        NSFileManager * fileManager = [NSFileManager defaultManager];
        NSMutableDictionary * attribs = [NSMutableDictionary dictionaryWithCapacity: 1];
        
        [attribs setObject: [NSNumber numberWithUnsignedLong: hfsType] forKey: NSFileHFSTypeCode];
        [fileManager changeFileAttributes: attribs atPath: path];
        return YES;
    }
    return NO;
}

// ---------------------------------

- (IBAction)saveDocumentAs: (id)sender
{
   NSSavePanel * savePanel = [NSSavePanel savePanel];
   NSString * imageDirectory, *imageName;
   
   if(!_imagePath) {
      _imagePath = [[[NSFileManager defaultManager] currentDirectoryPath] copy];
      imageDirectory = _imagePath;
      imageName = @"";
   } else {
      imageDirectory = _imagePath;
      imageName = [[_imagePath lastPathComponent] stringByDeletingPathExtension];
   }
   
   [savePanel setCanSelectHiddenExtension: YES];
   [savePanel setRequiredFileType: @"tiff"];
   [savePanel beginSheetForDirectory: imageDirectory
               file: imageName
               modalForWindow: [self window]
               modalDelegate: self
               didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
               contextInfo: savePanel];
}

// ---------------------------------

- (IBAction)saveDocument: (id)sender
{
    if(_imagePath) {
        NSData *	data = [self contentsAsDataOfType: NSTIFFPboardType];
        if(!data || !writeDataToFile(data, _imagePath, 'TIFF'))
            NSRunCriticalAlertPanel(@"Save Error",@"Unable to save current window contents.", @"OK", nil, nil);
    } else {
        [self saveDocumentAs: sender];
    }
}

// ---------------------------------

- (void)savePanelDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (id)savePanel
{
    if(returnCode == NSOKButton) {
        NSData * data = [self contentsAsDataOfType: NSTIFFPboardType];

        [_imagePath release];
        _imagePath = [[savePanel filename] copy];

        if(!data || !writeDataToFile(data, _imagePath, 'TIFF'))
            NSRunCriticalAlertPanel(@"Save Error",@"Unable to save current window contents.", @"OK", nil, nil);
    }
}

// ---------------------------------

- (IBAction)copy: (id)sender
{
    NSString * type = NSTIFFPboardType;
    NSData * imageData = [self contentsAsDataOfType: type];
        
    if(imageData) {
        NSPasteboard *	generalPboard = [NSPasteboard generalPasteboard];
        [generalPboard declareTypes: [NSArray arrayWithObjects: type, nil] owner: nil];
        [generalPboard setData: imageData forType: type];
    }
}

// ---------------------------------

- (void)pageLayoutDidEnd: (NSPageLayout *)pageLayout returnCode: (int)returnCode contextInfo: (id)printInfo
{
    if(returnCode == NSOKButton) {
        [NSPrintInfo setSharedPrintInfo: printInfo];
    }
}

// ---------------------------------

- (void)runPageLayout: (id)sender
{
   NSPageLayout * pageLayout = [NSPageLayout pageLayout];
   NSPrintInfo * printInfo = [NSPrintInfo sharedPrintInfo];
   
   [pageLayout beginSheetWithPrintInfo: printInfo
               modalForWindow: [self window]
               delegate: self
               didEndSelector: @selector(pageLayoutDidEnd:returnCode:contextInfo:)
               contextInfo: printInfo];
}

// ---------------------------------

- (void)print: (id)sender
{
    NSImage * tiffImage = [self imageWithTIFFInsideRect: [self bounds]];
    NSImageView * imageView = [[NSImageView alloc] initWithFrame: [self bounds]];
    [imageView setImage: tiffImage];
    
    if(imageView && tiffImage) {
        // set some reason state for GL printing, developers could spend more time here to get better results
        NSPrintInfo * printinfo = [NSPrintInfo sharedPrintInfo];
        [printinfo setHorizontalPagination: NSAutoPagination];
        [printinfo setVerticalPagination: NSAutoPagination];
        [printinfo setTopMargin: 0.0f];
        [printinfo setBottomMargin: 0.0f];
        [printinfo setRightMargin: 7.0f];
        [printinfo setLeftMargin: 7.0f];
        if ([imageView bounds].size.height < [imageView bounds].size.width)
            [printinfo setOrientation: NSLandscapeOrientation];
        else
            [printinfo setOrientation: NSPortraitOrientation];
        // print imageView
        NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView: imageView printInfo: printinfo];
        [printOperation	runOperationModalForWindow: [self window]
                        delegate: nil
                        didRunSelector: nil
                        contextInfo: nil];
    } else {
        NSRunCriticalAlertPanel(@"Print Error",@"Could not generate image data for printing.", @"OK", nil, nil);
    }
    
}

// ---------------------------------

- (void)prepareForMiniaturization:(NSNotification *)notification
{
    NSBitmapImageRep * bitmap = [self bitmapInsideRect: NSZeroRect];
    // if you want to update your icon youc an do the following
    // [[self window] setMiniwindowImage: [self imageWithTIFFInsideRect: NSZeroRect]];
   if([self lockFocusIfCanDraw]) {
      [bitmap drawAtPoint:NSZeroPoint];
      [self unlockFocus];
      [[self window] flushWindow];
   }
 }

// ---------------------------------

#pragma mark ---- Method Overrides ----

//get the color at the mouse point and print it out
- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (NSPointInRect(location, [self bounds])) {
		GLuint pixel;
	   
		[self lockFocus];
		while(glGetError() != GL_NO_ERROR);
		glPushAttrib(GL_ALL_ATTRIB_BITS);
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
			glReadBuffer(GL_BACK);
			
			glDisable(GL_COLOR_TABLE);
			glDisable(GL_CONVOLUTION_1D);
			glDisable(GL_CONVOLUTION_2D);
			glDisable(GL_HISTOGRAM);
			glDisable(GL_MINMAX);
			glDisable(GL_POST_COLOR_MATRIX_COLOR_TABLE);
			glDisable(GL_POST_CONVOLUTION_COLOR_TABLE);
			glDisable(GL_SEPARABLE_2D);
			
			//glPixelMapfv(GL_PIXEL_MAP_R_TO_R, 1, &zero);
			//glPixelMapfv(GL_PIXEL_MAP_G_TO_G, 1, &zero);
			//glPixelMapfv(GL_PIXEL_MAP_B_TO_B, 1, &zero);
			//glPixelMapfv(GL_PIXEL_MAP_A_TO_A, 1, &zero);
			
			glPixelStorei(GL_PACK_SWAP_BYTES, 0);
			glPixelStorei(GL_PACK_LSB_FIRST, 0);
			glPixelStorei(GL_PACK_IMAGE_HEIGHT, 0);
			glPixelStoref(GL_PACK_ROW_LENGTH, 1.0f); 
			//glPixelStoref(GL_PACK_SKIP_PIXELS, origin.x);
			//glPixelStoref(GL_PACK_SKIP_ROWS, 1.0f - (origin.y + 1.0f));
			glPixelStorei(GL_PACK_SKIP_IMAGES, 0);
			
			glPixelTransferi(GL_MAP_COLOR, 0);
			glPixelTransferf(GL_RED_SCALE, 1.0f);
			glPixelTransferf(GL_RED_BIAS, 0.0f);
			glPixelTransferf(GL_GREEN_SCALE, 1.0f);
			glPixelTransferf(GL_GREEN_BIAS, 0.0f);
			glPixelTransferf(GL_BLUE_SCALE, 1.0f);
			glPixelTransferf(GL_BLUE_BIAS, 0.0f);
			glPixelTransferf(GL_ALPHA_SCALE, 1.0f);
			glPixelTransferf(GL_ALPHA_BIAS, 0.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_RED_SCALE, 1.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_RED_BIAS, 0.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_SCALE, 1.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_BIAS, 0.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_SCALE, 1.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_BIAS, 0.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_SCALE, 1.0f);
			glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_BIAS, 0.0f);
			
			glReadPixels((GLint) location.x, (GLint) location.y,
						(GLsizei) 1, (GLsizei) 1,
						GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, &pixel);
			// Get rid of any error, in order to not mislead the rest of the app
		glPopClientAttrib();
		glPopAttrib();
		while(glGetError() != GL_NO_ERROR);
		//[self unlockFocus];
		//get values fill in
		[colorRText setIntValue:(pixel>>(8*3))&0xFF];
		[colorGText setIntValue:(pixel>>(8*2))&0xFF];
		[colorBText setIntValue:(pixel>>(8*1))&0xFF];
		[colorAText setIntValue:(pixel>>(8*0))&0xFF];
	} else {
		[colorRText setStringValue:@"NA"];
		[colorGText setStringValue:@"NA"];
		[colorBText setStringValue:@"NA"];
		[colorAText setStringValue:@"NA"];
	}
}

-(void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent characters];
    if ([characters length]) {
        unichar character = [characters characterAtIndex:0];
		switch (character) {
			default:
			break;
		}
	}
}

// ---------------------------------

- (void)mouseDown:(NSEvent *)theEvent // trackball
{
    if ([theEvent modifierFlags] & NSControlKeyMask) // send to pan
		[self rightMouseDown:theEvent];
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) // send to dolly
		[self otherMouseDown:theEvent];
	else {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		location.y = camera.viewHeight - location.y;
		gDolly = GL_FALSE; // no dolly
		gPan = GL_FALSE; // no pan
		gTrackball = GL_TRUE;
		startTrackball (location.x, location.y, 0, 0, camera.viewWidth, camera.viewHeight);
		gTrackingViewInfo = self;
	}
}

// ---------------------------------

- (void)rightMouseDown:(NSEvent *)theEvent // pan
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_FALSE; // no dolly
	gPan = GL_TRUE; 
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

// ---------------------------------

- (void)otherMouseDown:(NSEvent *)theEvent //dolly
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_TRUE;
	gPan = GL_FALSE; // no pan
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

// ---------------------------------

- (void)mouseUp:(NSEvent *)theEvent
{
	if (gDolly) { // end dolly
		gDolly = GL_FALSE;
	} else if (gPan) { // end pan
		gPan = GL_FALSE;
	} else if (gTrackball) { // end trackball
		gTrackball = GL_FALSE;
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	} 
	gTrackingViewInfo = NULL;
}

// ---------------------------------

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

// ---------------------------------

- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

// ---------------------------------

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) {
		rollToTrackball (location.x, location.y, gTrackBallRotation);
		[self setNeedsDisplay: YES];
	} else if (gDolly) {
		[self mouseDolly: location];
		[self updateProjection];  // update projection matrix (not normally done on draw)
		[self setNeedsDisplay: YES];
	} else if (gPan) {
		[self mousePan: location];
		[self setNeedsDisplay: YES];
	}
}

// ---------------------------------

- (void)scrollWheel:(NSEvent *)theEvent
{
	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
    if (wheelDelta) {
		GLfloat deltaAperture = wheelDelta * -camera.aperture / 200.0f;
		camera.aperture += deltaAperture;
		if (camera.aperture < 0.1) // do not let aperture <= 0.1
			camera.aperture = 0.1;
		if (camera.aperture > 179.9) // do not let aperture >= 180
			camera.aperture = 179.9;
		[self updateProjection]; // update projection matrix
		[self setNeedsDisplay: YES];
	}
}

// ---------------------------------

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

// ---------------------------------

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

// ---------------------------------

- (void) drawRect:(NSRect)rect
{
	[self prepareOpenGL]; // ensure we are setup
	glReportError ();
	
	// setup viewport and prespective
	[self resizeGL]; // forces projection matrix update (does test for size changes)
	[self updateModelView];  // update model view matrix for object
	glReportError ();
	if (glslSupport) {
		glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
		// clear our drawable
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glReportError ();
		
		// model view and projection matricies already set

		[self drawShape:drawObject]; // draw scene
			
		glReportError ();
		if ([self inLiveResize] && !fAnimate)
			glFlush ();
		else
			[[self openGLContext] flushBuffer];
		glReportError ();
		
	} else {
		
		glClearColor(0.8f, 0.2f, 0.2f, 1.0f);
		// clear our drawable
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glReportError ();
		if ([self inLiveResize] && !fAnimate)
			glFlush ();
		else
			[[self openGLContext] flushBuffer];
	}

	if (fChangingRenderers) {
		NSEnableScreenUpdates();
	}

	// update the current processing locations
	{
		GLint prevVertex = vertexGPUProcessing;
		GLint prevFragment = fragmentGPUProcessing;
		CGLGetParameter (CGLGetCurrentContext(), kCGLCPGPUVertexProcessing, &vertexGPUProcessing);
		CGLGetParameter (CGLGetCurrentContext(), kCGLCPGPUFragmentProcessing, &fragmentGPUProcessing);
		if (prevVertex != vertexGPUProcessing || prevFragment != fragmentGPUProcessing || fChangingRenderers)
			[controller updateProcessingWithVertex:vertexGPUProcessing withFragment:fragmentGPUProcessing withRenderer:(char *)glGetString (GL_RENDERER)];
		[controller performSelector:@selector(updateControlStrings)  withObject:NULL afterDelay:0.0];
	}
	fChangingRenderers = NO;
}

// ---------------------------------

- (void)rebuildObjects
{
	// build objects
	if (planeList)
		glDeleteLists (planeList, 1);
	planeList = glGenLists (1);
	glNewList(planeList, GL_COMPILE);
		[self planeWithSize:NSMakeSize(1.5f * 2.5f, 1.5f * 2.5f) withDivisions:40];
	glEndList();
	
	if (sphereList)
		glDeleteLists (sphereList, 1);
	sphereList = glGenLists (1);
	glNewList(sphereList, GL_COMPILE);
		[self sphereWithRadius:(1.5 * 1.5) withDivisions:40];
	glEndList();
	
	if (torusList)
		glDeleteLists (torusList, 1);
	torusList = glGenLists (1);
	glNewList(torusList, GL_COMPILE);
		[self doughnutWithInnerRadius:(1.5f * 0.45f) withOuterRadius:(1.5f * 0.89f) withDivisions:40 withRings:40];
	glEndList();
}

// ---------------------------------

// set initial OpenGL state (current context is set)
// called after context is created
- (void) prepareOpenGL
{
	if (NO == fGLInit) {
		int i;
		long swapInt = 1;
		BOOL firstPass = NO;
		fGLInit = YES; // do not init gl again for this context
		if (NULL == multiTexNames) // if we are here for the first time
			firstPass = YES;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync

		// init GL stuff here
		glEnable(GL_DEPTH_TEST);
		glEnable (GL_BLEND);
		glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 

		glShadeModel(GL_SMOOTH);    
		glPolygonOffset (1.0f, 1.0f);

//glEnable(GL_COLOR_MATERIAL);
//glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
		
		glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
		shapeSize = 7.0f; // max radius of of objects
		
		if (firstPass)
			[self resetCamera];
			
		if (firstPass) { // force update
			vertexGPUProcessing = -1;
			fragmentGPUProcessing = -1;
		}
		
		// set up textures
		glGetIntegerv(GL_MAX_TEXTURE_UNITS, &multiTexUnitCount);
		if (firstPass) {
			multiTexNames = malloc(kMaxTextureUnits * sizeof(GLuint));
			multiTexActiveFlags = malloc(kMaxTextureUnits * sizeof(int));
			multiTexTargets = malloc(kMaxTextureUnits * sizeof(GLenum));
			multiTexImages = malloc(kMaxTextureUnits * sizeof(NSImage *));
			for (i = 0; i < kMaxTextureUnits; i++) {
				multiTexNames[i] = 0;
				multiTexTargets[i] = 0;
				multiTexImages[i] = nil;
			}
		}	
		// load current images as textures...
		for (i = 0; i < kMaxTextureUnits; i++) {// clear and rebuild as required in all cases
			multiTexActiveFlags[i] = 0;
			NSImage * image = multiTexImages[i];
			if (image) { // if we already have an image for this unit, rebuild the texture
				[self useImageAsTexture:image forUnit:i withTarget:multiTexTargets[i]];
				[image release];
			}
		}

		[self rebuildObjects];

		// reset program and shader settings...
		fShader = false; // ensure using shader is off for renderer changes
		[controller invalidateObjects];
		
//set lighting state
		if(fSetState==YES)
		{
			fSetState=NO;
			if(lighting)
			{
				glEnable(GL_LIGHTING);
			}
			else
			{
				glDisable(GL_LIGHTING);
			}
			GLenum light;
			for(light=GL_LIGHT0;light<=GL_LIGHT7;light++)
			{
				if(lightsOn[light-GL_LIGHT0])
				{
					glEnable(light);
				}
				else
				{
					glDisable(light);
				}
				GLenum valueField[]={GL_AMBIENT,GL_DIFFUSE,GL_SPECULAR,GL_POSITION,GL_SPOT_DIRECTION,GL_SPOT_EXPONENT,GL_SPOT_CUTOFF,GL_CONSTANT_ATTENUATION,GL_LINEAR_ATTENUATION,GL_QUADRATIC_ATTENUATION};
				int field;
				for(field=0;field<sizeof(valueField)/sizeof(valueField[0]);field++)
				{
					glLightfv(light,valueField[field],lightParams[light-GL_LIGHT0][field]);
				}
			}
			if(fogging)
			{
				glEnable(GL_FOG);
			}
			else
			{
				glDisable(GL_FOG);
			}
			GLenum valueField[]={GL_FOG_COLOR,GL_FOG_DENSITY,GL_FOG_START,GL_FOG_END};
			int field;
			for(field=0;field<sizeof(valueField)/sizeof(valueField[0]);field++)
			{
				glFogfv(valueField[field],fogParams[field]);
			}
		}
	
		[self updateProjection];  // update projection matrix (not normally done on draw)
		[self checkGLSLSupport];
	}
}

// ---------------------------------

// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes.  So be
// careful of doing too much here.
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
	[super update];
	[self checkGLSLSupport];
}

// ---------------------------------

- (void) checkGLSLSupport
{
	if (!gluCheckExtension((const GLubyte *) "GL_ARB_shader_objects", glGetString (GL_EXTENSIONS)) || 
		!gluCheckExtension((const GLubyte *) "GL_ARB_vertex_shader", glGetString (GL_EXTENSIONS)) ||
		!gluCheckExtension((const GLubyte *) "GL_ARB_fragment_shader", glGetString (GL_EXTENSIONS)) || 
		!gluCheckExtension((const GLubyte *) "GL_ARB_shading_language_100", glGetString (GL_EXTENSIONS))) {
		glslSupport = NO;
	} else {
		glslSupport = YES;
	}
}

// ---------------------------------

-(BOOL) supportsGLSL;
{
	return glslSupport;
}

// ---------------------------------

- (void) setFloatRenderer: (int) state
{
	NSDisableScreenUpdates();
	fChangingRenderers = YES;
	fSoftwareRenderer = (state == NSOnState) ? YES : NO;
	if (YES == fGLInit)
		[self prepareForMiniaturization:nil]; // force back buffer update
//get lighting state
	if(YES == fGLInit)
	{
		fSetState=YES;
		lighting=glIsEnabled(GL_LIGHTING);
		GLenum light;
		for(light=GL_LIGHT0;light<=GL_LIGHT7;light++)
		{
			lightsOn[light-GL_LIGHT0]=glIsEnabled(light);
			GLenum valueField[]={GL_AMBIENT,GL_DIFFUSE,GL_SPECULAR,GL_POSITION,GL_SPOT_DIRECTION,GL_SPOT_EXPONENT,GL_SPOT_CUTOFF,GL_CONSTANT_ATTENUATION,GL_LINEAR_ATTENUATION,GL_QUADRATIC_ATTENUATION};
			int field;
			for(field=0;field<sizeof(valueField)/sizeof(valueField[0]);field++)
			{
				glGetLightfv(light,valueField[field],lightParams[light-GL_LIGHT0][field]);
			}
		}
		fogging=glIsEnabled(GL_FOG);
		GLenum valueField[]={GL_FOG_COLOR,GL_FOG_DENSITY,GL_FOG_START,GL_FOG_END};
		int field;
		for(field=0;field<sizeof(valueField)/sizeof(valueField[0]);field++)
		{
			glGetFloatv(valueField[field],fogParams[field]);
		}
	}
	else
	{
		fSetState=NO;
	}

	[self clearGLContext];
	[self setOpenGLContext:[[NSOpenGLContext alloc] initWithFormat: (state == NSOnState) ? [GLSLView floatPixelFormat] : [GLSLView basicPixelFormat] shareContext:nil]];

	[self setNeedsDisplay: YES];
	fGLInit = NO; // force re-init
	[[self openGLContext] release]; // cover the extra retain
}


// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	fSoftwareRenderer = NO;
	return [super initWithFrame: frameRect pixelFormat: [GLSLView basicPixelFormat]];
}

// ---------------------------------

- (BOOL)acceptsFirstResponder
{
  return YES;
}

// ---------------------------------

- (BOOL)becomeFirstResponder
{
  return  YES;
}

// ---------------------------------

- (BOOL)resignFirstResponder
{
  return YES;
}

// ---------------------------------

- (void) awakeFromNib
{
	setStartTime (); // get app start time
	
	// set start values...
	rVel[0] = 0.3; rVel[1] = 0.1; rVel[2] = 0.2; 
	rAccel[0] = 0.003; rAccel[1] = -0.005; rAccel[2] = 0.004;
	fAnimate = 0;
	time = CFAbsoluteTimeGetCurrent ();  // set animation time start time

	// start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
    
    // add minification observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForMiniaturization:) name:NSWindowWillMiniaturizeNotification object:nil];

	[[self window] setAcceptsMouseMovedEvents: YES];
}

// ---------------------------------

- (void) dealloc
{	
	int i;
	for (i = 0; i < kMaxTextureUnits; i++) {// cl
		if (multiTexImages[i])
			[multiTexImages[i] release];
	}
	free (multiTexNames);
	free (multiTexActiveFlags);
	free (multiTexTargets);
	free (multiTexImages);
    [super dealloc];
}

@end
