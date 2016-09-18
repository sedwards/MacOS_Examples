/* GLSLController */

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

  Copyright (c) 2004-2006 Apple Computer, Inc., All rights reserved.

*/

#import <Cocoa/Cocoa.h>
#import "uniformValue.h"

@class GLSLParser, GLSLView;

enum {
	kTexture2DType = 0,
	kTexture
};

@interface GLSLController : NSObject
{
	NSTabView *tabView;
	NSString *resultsString;
	NSString *logString;
	
	NSString *vertexString;
	NSString *fragmentString;
	NSColor *vertexColor;
	NSColor *fragmentColor;
	
	bool terminating;
	
	int numberUniforms;
	int matrixColumn;
	int currentMatrixStride;

    IBOutlet GLSLView * glView;
    IBOutlet NSTextView * logTextView;
    IBOutlet GLSLParser * parser;
    IBOutlet NSTextView * resultsTextView;
    IBOutlet NSButton * animateButton;
    IBOutlet NSButton * forceFloatRendererButton;
    IBOutlet NSButton * autoLinkButton;
	IBOutlet NSTextField *linkResultText;
	IBOutlet NSTextField *glslSupportText;
	IBOutlet NSTextField *vertexRendererText;
	IBOutlet NSTextField *fragmentRendererText;
	IBOutlet NSButton *useShaderButton;
	IBOutlet NSPopUpButton *objectPopUp;
	IBOutlet NSPopUpButton *unformPullDown;
	
	IBOutlet NSTextField *uniformInfo;
	IBOutlet NSTextField *uniformStatus;
	IBOutlet NSTextField *uniformXValue;
	IBOutlet NSTextField *uniformYValue;
	IBOutlet NSTextField *uniformZValue;
	IBOutlet NSTextField *uniformWValue;
	IBOutlet NSTextField *uniformXMin;
	IBOutlet NSTextField *uniformYMin;
	IBOutlet NSTextField *uniformZMin;
	IBOutlet NSTextField *uniformWMin;
	IBOutlet NSTextField *uniformXMax;
	IBOutlet NSTextField *uniformYMax;
	IBOutlet NSTextField *uniformZMax;
	IBOutlet NSTextField *uniformWMax;
	IBOutlet NSSlider *uniformXSlider;
	IBOutlet NSSlider *uniformYSlider;
	IBOutlet NSSlider *uniformZSlider;
	IBOutlet NSSlider *uniformWSlider;
	IBOutlet NSColorWell *uniformColor;
	IBOutlet NSPopUpButton *uniformColumnPopUp;
	IBOutlet NSTextField *uniformIntResult;
	IBOutlet NSTextField *uniformFloatResult;
	
	IBOutlet NSImageView *textureUnit0ImageView;
	IBOutlet NSImageView *textureUnit1ImageView;
	IBOutlet NSImageView *textureUnit2ImageView;
	IBOutlet NSImageView *textureUnit3ImageView;
	IBOutlet NSImageView *textureUnit4ImageView;
	IBOutlet NSImageView *textureUnit5ImageView;
	IBOutlet NSImageView *textureUnit6ImageView;
	IBOutlet NSImageView *textureUnit7ImageView;
	IBOutlet NSTextField *textureSize;
	IBOutlet NSTextField *textureOriginalSize;
	IBOutlet NSPopUpButton *textureTargetPopUp;

	NSSize textureOriginalSizes[8]; // the original size of the image (current size is in the image itself)
	GLenum textureTarget[8]; // the enum of the texture target, this is the tag of the pop up menu item
	
	IBOutlet NSButton* lightsEnable;//on or off -- GL_LIGHTING
	//IBOutlet NSPopUpButton* lightsType;//ambient,directional,point,spot -- 
	IBOutlet NSPopUpButton* lightsNum;//GL_LIGHT0,GL_LIGHT1,GL_LIGHT2,GL_LIGHT3,...
	IBOutlet NSPopUpButton* lightsValues;//GL_AMBIENT(4),GL_DIFFUSE(4),GL_SPECULAR(4),GL_POSITION(4),GL_SPOT_DIRECTION(3),GL_SPOT_EXPONENT(1),GL_SPOT_CUTOFF(1)
	IBOutlet NSFormCell* lightXValue;
	IBOutlet NSFormCell* lightYValue;
	IBOutlet NSFormCell* lightZValue;
	IBOutlet NSFormCell* lightWValue;
	IBOutlet NSButton* lightOn;
	IBOutlet NSPopUpButton* lightsPreset;//Custom,Ambient,Directional,Point,Spot

	IBOutlet NSButton* fogEnable;//on or off -- GL_LIGHTING
	IBOutlet NSPopUpButton* fogValues;//GL_FOG_COLOR(4),GL_FOG_DENSITY(1),GL_FOG_START(1),GL_FOG_END(1)
	IBOutlet NSFormCell* fogXValue;
	IBOutlet NSFormCell* fogYValue;
	IBOutlet NSFormCell* fogZValue;
	IBOutlet NSFormCell* fogWValue;

    NSMutableDictionary * stanStringAttrib;
    NSMutableDictionary * errorStringAttrib;
	
	NSMutableDictionary * uniformValues; // stores uniformValue objects
	uniformValue * currentUniformValue; // contains all info about current Uniform
	NSString * currentUniformName;
	GLenum currentUniformType;
	GLint currentUniformSize;
	int currentLocation;
}

- (NSTextField *) linkResultTextField;
- (BOOL) usingShaderPraogram;
- (void) changeFirstResponder:(NSResponder *)aResponder;

- (void) setResultsString:(NSString *)value;
- (void) updateResultsView;
- (void) setLogString:(NSString *)value;
- (void) appendLogString:(NSString *)value;
- (void) clearLogString;

- (void) setLinkText:(NSString *)string;

- (void) updateProcessingWithVertex:(GLint)vertex withFragment:(GLint)fragment withRenderer:(char *)renderer;
- (void) updateControlStrings;

- (NSPopUpButton *)getUniformPullDown;
- (void) setNumUniforms:(int)numUniforms;
- (void) setUnformControls; // after link set current control settings
- (void) setUniformInfo:(char *)name withLocation:(int)location withLength:(GLsizei)length withType:(GLenum)type withSize:(GLint)size;
- (void) setUniformFloatData:(GLfloat *)fVal;
- (void) setUniformIntData:(GLint *)iVal;
- (void) disableUniforms;
- (void) addUniformWithTitle:(NSString *)title; // looks in uniformValues dict for key, adds if not there, setting default min and max

- (IBAction)changeTextureTarget: (id) sender;
- (IBAction)uniformColumnChange:(id)sender;
- (IBAction)uniformMinMaxChange:(id)sender;
- (IBAction)uniformColorChange:(id)sender;
- (IBAction)uniformValueChange:(id)sender;
- (IBAction)selectUniform:(id)sender;
- (IBAction)autoLink:(id)sender;
- (IBAction)link:(id)sender;
- (IBAction)animateToggle:(id)sender;
- (IBAction)floatRendererToggle:(id)sender;
- (IBAction)objectToggle:(id)sender;
- (void)useShader;
- (IBAction)useShaderToggle:(id)sender;
- (IBAction)textureImageDropped:(id)sender;

- (IBAction)lightToggle:(id)sender;
- (IBAction)lightEnableChange:(id)sender;
- (IBAction)lightNumChange:(id)sender;
- (IBAction)lightTypeChange:(id)sender;
- (IBAction)lightValueChange:(id)sender;
- (IBAction)lightsResetLight:(id)sender;
- (IBAction)lightsReset:(id)sender;
- (IBAction)lightsPreset:(id)sender;
- (void)lightUpdate:(GLenum*)pLight:(GLenum*)pValueField;
- (void)lightFixValues;

- (IBAction)fogEnableChange:(id)sender;
- (IBAction)fogTypeChange:(id)sender;
- (IBAction)fogValueChange:(id)sender;
- (void)fogUpdate:(GLenum*)pValueField;
- (void)fogFixValues;

- (void)setCurrent; // ensure the gl context is initialized and current
- (void)shaderRedraw; // redraw if shader is being used, should be called after re-link or uniform change

- (void) invalidateObjects; // called to invalidate all shader and program objects on renderer change

@end
