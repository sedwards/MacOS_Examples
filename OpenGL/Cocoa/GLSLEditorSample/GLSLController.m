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

  Copyright (c) 2004-2005 Apple Computer, Inc., All rights reserved.
  
*/

#import "GLSLParser.h"
#import "GLSLView.h"
#import "GLSLController.h"
#import "MyDocument.h"

NSString *gUniformValueKey = @"Uniform Values";

@implementation GLSLController

- (NSString *)resultsString 
{
	return resultsString;
}

- (void) setResultsString:(NSString *)value
{
	[value retain];
	[resultsString release];
	resultsString = value;
}

- (void) updateResultsString
{
	[self setResultsString: [resultsTextView string]];
}

- (void) updateResultsView
{
	[resultsTextView setString: [self resultsString]];
}

// -----

- (NSString *)logString 
{
	return logString;
}

- (void) setLogString:(NSString *)value
{
	[value retain];
	[logString release];
	logString = value;
	[logTextView setString: [self logString]];
}

- (void) appendLogString:(NSString *)value
{
	NSString *newString = [logString stringByAppendingString:value];
	[newString retain];
	// do I need a retain here???
	[logString release];
	logString = newString;
	[logTextView setString: [self logString]];
}

- (void) clearLogString
{
	NSString *newString = [NSString stringWithFormat:@""];
	[newString retain];
	[logString release];
	logString = newString;
	[logTextView setString: [self logString]];
}

- (NSPopUpButton *)getUniformPullDown
{
	return unformPullDown;
}


- (void) setUnformControls; // after link set current control settings
{
	if ([unformPullDown isEnabled] && 0 < [unformPullDown numberOfItems]) {
		int i;
		if (currentUniformName)
			[unformPullDown selectItemWithTitle:currentUniformName];
		if (nil == [unformPullDown selectedItem])
			[unformPullDown selectItemAtIndex:0];
		if ([useShaderButton state]) // first set all the unform values...  (need to walk menu and set)
			for (i = 0; i < [unformPullDown numberOfItems]; i++) {
				[parser setCurrentUniform:i]; // set every item in turn
			}
		// end with last item to ensure data is updated...
		[parser setCurrentUniform:[unformPullDown indexOfSelectedItem]]; // this will first item after link
	}
}

// -----

- (void)willTerminate:(NSNotification *)notif
{
    NSData *archivedDefaults =
        [NSArchiver archivedDataWithRootObject: uniformValues];
    [[NSUserDefaults standardUserDefaults] setObject:archivedDefaults forKey:gUniformValueKey];

	// app is done
	terminating = true;
}

// update the processing string
// the renderer will always show current fragment renderer not requested
- (void) updateProcessingWithVertex:(GLint)vertexGPU withFragment:(GLint)fragmentGPU withRenderer:(char *)renderer;
{
	[vertexString release];
	[vertexColor release];
	[fragmentString release];
	[fragmentColor release];
	// note really we just want the primary renderer cpabilities and compare
	if (NSOnState != [forceFloatRendererButton state]) { // expecting hardware case
		if (vertexGPU) {
			vertexColor = [[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f] retain];
			vertexString = [[NSString stringWithFormat:@"%s",renderer] retain];		
		} else { // fallback
			vertexColor = [[NSColor colorWithCalibratedRed:1.0f green:0.5f blue:0.5f alpha:1.0f] retain];
			vertexString = [[NSString stringWithFormat:@"Apple Software Renderer"] retain];
		}
		fragmentString = [[NSString stringWithFormat:@"%s",renderer] retain]; // always same as current renderer	
		if (fragmentGPU) {
			fragmentColor = [[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f] retain];
		} else { // fallback
			fragmentColor = [[NSColor colorWithCalibratedRed:1.0f green:0.5f blue:0.5f alpha:1.0f] retain];
		}
	} else { // software case
		if (vertexGPU)
			printf ("updateProcessingWithVertex:withFragment:withRenderer: error vertex GPU processing wrong\n"); 
		if (fragmentGPU)
			printf ("updateProcessingWithVertex:withFragment:withRenderer: error fragment GPU processing wrong\n"); 
		vertexString = [[NSString stringWithFormat:@"%s",renderer] retain];		
		fragmentString = [[NSString stringWithFormat:@"%s",renderer] retain]; // always same as current renderer	
		vertexColor = [[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f] retain];
		fragmentColor = [[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f] retain];
	}
}

- (void) updateControlStrings
{
	[vertexRendererText setStringValue:vertexString];
	[vertexRendererText setBackgroundColor:vertexColor];
	[fragmentRendererText setStringValue:fragmentString];
	[fragmentRendererText setBackgroundColor:fragmentColor];
	[glslSupportText setHidden:[glView supportsGLSL]];
}

// -----

- (IBAction)uniformColumnChange:(id)sender
{
	matrixColumn = [uniformColumnPopUp indexOfSelectedItem];
	[parser setCurrentUniform:[unformPullDown indexOfSelectedItem]]; 
}

// -----

- (IBAction)uniformMinMaxChange:(id)sender
{
	[currentUniformValue setMinVal:(float)[uniformXMin intValue] atIndex:0 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMinVal:(float)[uniformYMin intValue] atIndex:1 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMinVal:(float)[uniformZMin intValue] atIndex:2 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMinVal:(float)[uniformWMin intValue] atIndex:3 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMaxVal:(float)[uniformXMax intValue] atIndex:0 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMaxVal:(float)[uniformYMax intValue] atIndex:1 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMaxVal:(float)[uniformZMax intValue] atIndex:2 + currentMatrixStride * matrixColumn];
	[currentUniformValue setMaxVal:(float)[uniformWMax intValue] atIndex:3 + currentMatrixStride * matrixColumn];
	[uniformXSlider setMinValue:(int)[currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn]];
	[uniformXSlider setMaxValue:(int)[currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn]];
	[uniformYSlider setMinValue:(int)[currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn]];
	[uniformYSlider setMaxValue:(int)[currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn]];
	[uniformZSlider setMinValue:(int)[currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn]];
	[uniformZSlider setMaxValue:(int)[currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn]];
	[uniformWSlider setMinValue:(int)[currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn]];
	[uniformWSlider setMaxValue:(int)[currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn]];
	switch (currentUniformType) { // get type in text form
		case GL_INT:
		case GL_INT_VEC2_ARB:
		case GL_INT_VEC3_ARB:
		case GL_INT_VEC4_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			[uniformXSlider setNumberOfTickMarks:(int)([currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn] + 1)];
			[uniformXSlider setAllowsTickMarkValuesOnly: true];
			if  ([uniformYValue isEnabled]) {
				[uniformYSlider setNumberOfTickMarks:(int)([currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn] + 1)];
				[uniformYSlider setAllowsTickMarkValuesOnly: true];
			}
			if  ([uniformZValue isEnabled]) {
				[uniformZSlider setNumberOfTickMarks:(int)([currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn] + 1)];
				[uniformZSlider setAllowsTickMarkValuesOnly: true];
			}
			if  ([uniformWValue isEnabled]) {
				[uniformWSlider setNumberOfTickMarks:(int)([currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn] + 1)];
				[uniformWSlider setAllowsTickMarkValuesOnly: true];
			}
			break;
		default:
			break;
	}
}

- (IBAction)uniformValueChange:(id)sender
{
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_FLOAT_VEC2_ARB:
		case GL_FLOAT_VEC3_ARB:
		case GL_FLOAT_VEC4_ARB:
		case GL_FLOAT_MAT2_ARB:
		case GL_FLOAT_MAT3_ARB:
		case GL_FLOAT_MAT4_ARB:
			[currentUniformValue setCurrentVal:[uniformXSlider floatValue] atIndex:0 + currentMatrixStride * matrixColumn];
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformXSlider floatValue]]];
			if  ([uniformYValue isEnabled]) {
				[currentUniformValue setCurrentVal:[uniformYSlider floatValue] atIndex:1 + currentMatrixStride * matrixColumn];
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformYSlider floatValue]]];
			}
			if  ([uniformZValue isEnabled]) {
				[currentUniformValue setCurrentVal:[uniformZSlider floatValue] atIndex:2 + currentMatrixStride * matrixColumn];
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformZSlider floatValue]]];
			}
			if  ([uniformWValue isEnabled]) {
				[currentUniformValue setCurrentVal:[uniformWSlider floatValue] atIndex:3 + currentMatrixStride * matrixColumn];
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformWSlider floatValue]]];
			} 
			if ([glView usingShader])
				[parser setUniformFloat: currentUniformValue];
			break;
		case GL_INT:
		case GL_INT_VEC2_ARB:
		case GL_INT_VEC3_ARB:
		case GL_INT_VEC4_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			[currentUniformValue setCurrentVal:(float)[uniformXSlider intValue] atIndex:0 + currentMatrixStride * matrixColumn];
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformXSlider intValue]]];
			if  ([uniformYValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformYSlider intValue] atIndex:1 + currentMatrixStride * matrixColumn];
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformYSlider intValue]]];
			}
			if  ([uniformZValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformZSlider intValue] atIndex:2 + currentMatrixStride * matrixColumn];
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformZSlider intValue]]];
			}
			if  ([uniformWValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformWSlider intValue] atIndex:3 + currentMatrixStride * matrixColumn];
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformWSlider intValue]]];
			} 
			if ([glView usingShader])
				[parser setUniformInt: currentUniformValue];
			break;
		case GL_BOOL_ARB:
		case GL_BOOL_VEC2_ARB:
		case GL_BOOL_VEC3_ARB:
		case GL_BOOL_VEC4_ARB:
			[currentUniformValue setCurrentVal:(float)[uniformXSlider intValue] atIndex:0 + currentMatrixStride * matrixColumn];
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformXSlider intValue]]];
			if  ([uniformYValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformYSlider intValue] atIndex:1 + currentMatrixStride * matrixColumn];
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformYSlider intValue]]];
			}
			if  ([uniformZValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformZSlider intValue] atIndex:2 + currentMatrixStride * matrixColumn];
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformZSlider intValue]]];
			}
			if  ([uniformWValue isEnabled]) {
				[currentUniformValue setCurrentVal:(float)[uniformWSlider intValue] atIndex:3 + currentMatrixStride * matrixColumn];
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%ld", [uniformWSlider intValue]]];
			} 
			if ([glView usingShader])
				[parser setUniformInt: currentUniformValue];
			break;
		default:
			break;
	}
	if ([uniformColor isEnabled]) {
		// copy to color
		if (currentUniformType == GL_FLOAT_VEC3_ARB || currentUniformType == GL_FLOAT_MAT3_ARB)
			[uniformColor setColor:[NSColor colorWithCalibratedRed:[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn] 
			                                                   green:[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn] 
															   blue:[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn] 
															   alpha:1.0]];
		else
			[uniformColor setColor:[NSColor colorWithCalibratedRed:[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn] 
			                                                   green:[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn] 
															   blue:[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn] 
															   alpha:[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]]];
	}

	[self shaderRedraw];
}

- (IBAction)uniformColorChange:(id)sender
{
    NSColor *rgbColor;
	
    rgbColor = [[uniformColor color] colorUsingColorSpaceName:@"NSDeviceRGBColorSpace"];
    if (!rgbColor) // handle failure case
	    rgbColor = [NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.0]; // default
    [currentUniformValue setCurrentVal:[rgbColor redComponent] atIndex:0 + currentMatrixStride * matrixColumn];
    [currentUniformValue setCurrentVal:[rgbColor greenComponent] atIndex:1 + currentMatrixStride * matrixColumn];
    [currentUniformValue setCurrentVal:[rgbColor blueComponent] atIndex:2 + currentMatrixStride * matrixColumn];
		
	[uniformXSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]];
	[uniformXValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformXSlider floatValue]]];

	[uniformYSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]];
	[uniformYValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformYSlider floatValue]]];

	[uniformZSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]];
	[uniformZValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformZSlider floatValue]]];
	if (currentUniformType == GL_FLOAT_VEC4_ARB || currentUniformType == GL_FLOAT_MAT4_ARB) {
		[currentUniformValue setCurrentVal:[rgbColor alphaComponent] atIndex:3 + currentMatrixStride * matrixColumn];
		[uniformWSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]];
		[uniformWValue setStringValue:[NSString stringWithFormat:@"%0.3f", [uniformWSlider floatValue]]];
	} 
	[parser setUniformFloat: currentUniformValue];
	[self shaderRedraw];
}

- (IBAction)selectUniform:(id)sender
{
	// ensure when selecting a new uniform the column is zero
	matrixColumn = 0;
	[parser setCurrentUniform:[unformPullDown indexOfSelectedItem]]; 
}

- (void) setNumUniforms:(int)numUniforms;
{
	numberUniforms = numUniforms;
}

- (void) setUniformInfo:(char *)name withLocation:(int)location withLength:(GLsizei)length withType:(GLenum)type withSize:(GLint)size 
{
	NSString * string, *finalString;
	// set info
	NSString * oldName = currentUniformName;
	currentUniformName = [[NSString stringWithUTF8String:name] retain];
	[oldName release];
	
	// get current values
	uniformValue * temp = currentUniformValue;
	currentUniformValue = [[uniformValues objectForKey:currentUniformName] retain]; // look for uniform name in dictionary
	[temp release];
	if (nil == currentUniformValue)
		NSLog(@"current uniform not found in dictionary, this IS an error. %s", name);
	
	currentUniformType = type;
	currentLocation = location;

	if (![useShaderButton state])
		[uniformStatus setStringValue:@"--- Shader not in use, uniforms can't be set. ---"];
	else
		[uniformStatus setStringValue:@" "];

	finalString = [NSString stringWithFormat:@"OpenGL type: "];
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: finalString = [finalString stringByAppendingString:@"GL_FLOAT"]; break;
		case GL_FLOAT_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_VEC2_ARB"]; break;
		case GL_FLOAT_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_VEC3_ARB"]; break;
		case GL_FLOAT_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_VEC4_ARB"]; break;
		case GL_INT:  finalString = [finalString stringByAppendingString:@"GL_INT"]; break;
		case GL_INT_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"GL_INT_VEC2_ARB"]; break;
		case GL_INT_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"GL_INT_VEC3_ARB"]; break;
		case GL_INT_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"GL_INT_VEC4_ARB"]; break;
		case GL_BOOL_ARB:  finalString = [finalString stringByAppendingString:@"GL_BOOL_ARB"]; break;
		case GL_BOOL_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"GL_BOOL_VEC2_ARB"]; break;
		case GL_BOOL_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"GL_BOOL_VEC3_ARB"]; break;
		case GL_BOOL_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"GL_BOOL_VEC4_ARB"]; break;
		case GL_FLOAT_MAT2_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_MAT2_ARB"]; break;
		case GL_FLOAT_MAT3_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_MAT3_ARB"]; break;
		case GL_FLOAT_MAT4_ARB:  finalString = [finalString stringByAppendingString:@"GL_FLOAT_MAT4_ARB"]; break;
		case GL_SAMPLER_1D_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_1D_ARB"]; break;
		case GL_SAMPLER_2D_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_2D_ARB"]; break;
		case GL_SAMPLER_3D_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_3D_ARB"]; break;
		case GL_SAMPLER_CUBE_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_CUBE_ARB"]; break;
		case GL_SAMPLER_1D_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_1D_SHADOW_ARB"]; break;
		case GL_SAMPLER_2D_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_2D_SHADOW_ARB"]; break;
		case GL_SAMPLER_2D_RECT_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_2D_RECT_ARB"]; break;
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"GL_SAMPLER_2D_RECT_SHADOW_ARB"]; break;
		default: finalString = [finalString stringByAppendingString:@"(No type info)"]; break;
	}
	if (size > 1)
		string = [NSString stringWithFormat:@" Size: %ld\n", size];
	else if (size == 0)
		string = [NSString stringWithFormat:@" (No size info)\n"];
	else
		string = [NSString stringWithFormat:@" "];
	finalString = [finalString stringByAppendingString:string];
	[uniformInfo setStringValue:finalString];
	
	// based on type turn controls on or off
	[uniformXValue setEnabled:[useShaderButton state]];
	[uniformXMin setEnabled:[useShaderButton state]];
	[uniformXMax setEnabled:[useShaderButton state]];
	[uniformXSlider setEnabled:[useShaderButton state]];
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_INT:
		case GL_BOOL_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			currentMatrixStride = 1;

			[uniformYValue setEnabled:false];
			[uniformYMin setEnabled:false];
			[uniformYMax setEnabled:false];
			[uniformYSlider setEnabled:false];
			[uniformZValue setEnabled:false];
			[uniformZMin setEnabled:false];
			[uniformZMax setEnabled:false];
			[uniformZSlider setEnabled:false];
			[uniformWValue setEnabled:false];
			[uniformWMin setEnabled:false];
			[uniformWMax setEnabled:false];
			[uniformWSlider setEnabled:false];
		
			[uniformColumnPopUp setEnabled:false];
			break;
		case GL_FLOAT_VEC2_ARB:
		case GL_INT_VEC2_ARB:
		case GL_BOOL_VEC2_ARB:
		case GL_FLOAT_MAT2_ARB:
			currentMatrixStride = 2;

			[uniformYValue setEnabled:[useShaderButton state]];
			[uniformYMin setEnabled:[useShaderButton state]];
			[uniformYMax setEnabled:[useShaderButton state]];
			[uniformYSlider setEnabled:[useShaderButton state]];
			[uniformZValue setEnabled:false];
			[uniformZMin setEnabled:false];
			[uniformZMax setEnabled:false];
			[uniformZSlider setEnabled:false];
			[uniformWValue setEnabled:false];
			[uniformWMin setEnabled:false];
			[uniformWMax setEnabled:false];
			[uniformWSlider setEnabled:false];
		
			[uniformColumnPopUp setEnabled:false];
			break;
		case GL_FLOAT_VEC3_ARB:
		case GL_INT_VEC3_ARB:
		case GL_BOOL_VEC3_ARB:
		case GL_FLOAT_MAT3_ARB:
			currentMatrixStride = 3;

			[uniformYValue setEnabled:[useShaderButton state]];
			[uniformYMin setEnabled:[useShaderButton state]];
			[uniformYMax setEnabled:[useShaderButton state]];
			[uniformYSlider setEnabled:[useShaderButton state]];
			[uniformZValue setEnabled:[useShaderButton state]];
			[uniformZMin setEnabled:[useShaderButton state]];
			[uniformZMax setEnabled:[useShaderButton state]];
			[uniformZSlider setEnabled:[useShaderButton state]];
			[uniformWValue setEnabled:false];
			[uniformWMin setEnabled:false];
			[uniformWMax setEnabled:false];
			[uniformWSlider setEnabled:false];
		
			[uniformColumnPopUp setEnabled:false];
			break;
		case GL_FLOAT_VEC4_ARB:
		case GL_INT_VEC4_ARB:
		case GL_BOOL_VEC4_ARB:
		case GL_FLOAT_MAT4_ARB:
			currentMatrixStride = 4;

			[uniformYValue setEnabled:[useShaderButton state]];
			[uniformYMin setEnabled:[useShaderButton state]];
			[uniformYMax setEnabled:[useShaderButton state]];
			[uniformYSlider setEnabled:[useShaderButton state]];
			[uniformZValue setEnabled:[useShaderButton state]];
			[uniformZMin setEnabled:[useShaderButton state]];
			[uniformZMax setEnabled:[useShaderButton state]];
			[uniformZSlider setEnabled:[useShaderButton state]];
			[uniformWValue setEnabled:[useShaderButton state]];
			[uniformWMin setEnabled:[useShaderButton state]];
			[uniformWMax setEnabled:[useShaderButton state]];
			[uniformWSlider setEnabled:[useShaderButton state]];
		
		default:
			break;
	}
	[uniformColumnPopUp removeAllItems];
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT_MAT2_ARB:
			currentMatrixStride = 2;
			[uniformColumnPopUp addItemWithTitle:@"0"];
			[uniformColumnPopUp addItemWithTitle:@"1"];
			[uniformColumnPopUp setEnabled:[useShaderButton state]];
			[uniformColumnPopUp selectItemAtIndex: matrixColumn];
			break;
		case GL_FLOAT_MAT3_ARB:
			currentMatrixStride = 3;
			[uniformColumnPopUp addItemWithTitle:@"0"];
			[uniformColumnPopUp addItemWithTitle:@"1"];
			[uniformColumnPopUp addItemWithTitle:@"2"];
			[uniformColumnPopUp setEnabled:[useShaderButton state]];
			[uniformColumnPopUp selectItemAtIndex: matrixColumn];
			break;
		case GL_FLOAT_MAT4_ARB:
			currentMatrixStride = 4;
			[uniformColumnPopUp addItemWithTitle:@"0"];
			[uniformColumnPopUp addItemWithTitle:@"1"];
			[uniformColumnPopUp addItemWithTitle:@"2"];
			[uniformColumnPopUp addItemWithTitle:@"3"];
			[uniformColumnPopUp setEnabled:[useShaderButton state]];
			[uniformColumnPopUp selectItemAtIndex: matrixColumn];
			break;
		default:
			currentMatrixStride = 0;
			[uniformColumnPopUp setEnabled:false];
			break;
	}
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_INT:
		case GL_BOOL_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
		case GL_FLOAT_MAT2_ARB:
		case GL_FLOAT_VEC2_ARB:
		case GL_INT_VEC2_ARB:
		case GL_BOOL_VEC2_ARB:
		case GL_INT_VEC3_ARB:
		case GL_BOOL_VEC3_ARB:
		case GL_INT_VEC4_ARB:
		case GL_BOOL_VEC4_ARB:
			[uniformColor setEnabled:false];
			break;
		case GL_FLOAT_VEC4_ARB:
		case GL_FLOAT_VEC3_ARB:
		case GL_FLOAT_MAT3_ARB:
		case GL_FLOAT_MAT4_ARB:
			[uniformColor setEnabled:[useShaderButton state]];
			break;
		default:
			break;
	}
	
	[uniformXSlider setMinValue:[currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn]];
	[uniformXSlider setMaxValue:[currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn]];
	[uniformXMin setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn]]];
	[uniformXMax setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn]]];
	if  ([uniformYValue isEnabled]) {
		[uniformYSlider setMinValue:[currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn]];
		[uniformYSlider setMaxValue:[currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn]];
		[uniformYMin setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn]]];
		[uniformYMax setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn]]];
	} else {
		[uniformYSlider setMinValue:0.0];
		[uniformYSlider setMaxValue:1.0];
		[uniformYMin setStringValue:[NSString stringWithFormat:@"0.0"]];
		[uniformYMax setStringValue:[NSString stringWithFormat:@"1.0"]];
	}
	if  ([uniformZValue isEnabled]) {
		[uniformZSlider setMinValue:[currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn]];
		[uniformZSlider setMaxValue:[currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn]];
		[uniformZMin setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn]]];
		[uniformZMax setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn]]];
	} else {
		[uniformZSlider setMinValue:0.0];
		[uniformZSlider setMaxValue:1.0];
		[uniformZMin setStringValue:[NSString stringWithFormat:@"0.0"]];
		[uniformZMax setStringValue:[NSString stringWithFormat:@"1.0"]];
	}
	if  ([uniformWValue isEnabled]) {
		[uniformWSlider setMinValue:[currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn]];
		[uniformWSlider setMaxValue:[currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn]];
		[uniformWMin setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn]]];
		[uniformWMax setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn]]];
	} else {
		[uniformWSlider setMinValue:0.0];
		[uniformWSlider setMaxValue:1.0];
		[uniformWMin setStringValue:[NSString stringWithFormat:@"0.0"]];
		[uniformWMax setStringValue:[NSString stringWithFormat:@"1.0"]];
	}


// need to set initial values
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_FLOAT_VEC2_ARB:
		case GL_FLOAT_VEC3_ARB:
		case GL_FLOAT_VEC4_ARB:
		case GL_FLOAT_MAT2_ARB:
		case GL_FLOAT_MAT3_ARB:
		case GL_FLOAT_MAT4_ARB:
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%0.3f", [currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]]];
			[uniformXSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]];
			[uniformXSlider setNumberOfTickMarks:0];
			[uniformXSlider setAllowsTickMarkValuesOnly: false];
			if  ([uniformYValue isEnabled]) {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%0.3f", [currentUniformValue getCurrentValAtIndex:2] + currentMatrixStride * matrixColumn]];
				[uniformYSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]];
				[uniformYSlider setNumberOfTickMarks:0];
				[uniformYSlider setAllowsTickMarkValuesOnly: false];
			} else {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"0.0"]];
				[uniformYSlider setFloatValue: 0.0];
				[uniformYSlider setNumberOfTickMarks:0];
				[uniformYSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformZValue isEnabled]) {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%0.3f", [currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]]];
				[uniformZSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]];
				[uniformZSlider setNumberOfTickMarks:0];
				[uniformZSlider setAllowsTickMarkValuesOnly: false];
			} else {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"0.0"]];
				[uniformZSlider setFloatValue: 0.0];
				[uniformZSlider setNumberOfTickMarks:0];
				[uniformZSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformWValue isEnabled]) {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%0.3f", [currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]]];
				[uniformWSlider setFloatValue: [currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]];
				[uniformWSlider setNumberOfTickMarks:0];
				[uniformWSlider setAllowsTickMarkValuesOnly: false];
			} else {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"0.0"]];
				[uniformWSlider setFloatValue: 0.0];
				[uniformWSlider setNumberOfTickMarks:0];
				[uniformWSlider setAllowsTickMarkValuesOnly: false];
			}
			if ([glView usingShader])
				[parser setUniformFloat: currentUniformValue];
			break;
		case GL_INT:
		case GL_INT_VEC2_ARB:
		case GL_INT_VEC3_ARB:
		case GL_INT_VEC4_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]]];
			[uniformXSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]];
			[uniformXSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn] + 1)];
			[uniformXSlider setAllowsTickMarkValuesOnly: true];
			if  ([uniformYValue isEnabled]) {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]]];
				[uniformYSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]];
				[uniformYSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn] + 1)];
				[uniformYSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformYSlider setIntValue: 0];
				[uniformYSlider setNumberOfTickMarks:0];
				[uniformYSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformZValue isEnabled]) {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]]];
				[uniformZSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]];
				[uniformZSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn] + 1)];
				[uniformZSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformZSlider setIntValue: 0];
				[uniformZSlider setNumberOfTickMarks:0];
				[uniformZSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformWValue isEnabled]) {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]]];
				[uniformWSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]];
				[uniformWSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn] + 1)];
				[uniformWSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformWSlider setIntValue: 0];
				[uniformWSlider setNumberOfTickMarks:0];
				[uniformWSlider setAllowsTickMarkValuesOnly: false];
			}
			if ([glView usingShader])
				[parser setUniformInt: currentUniformValue];
			break;
		case GL_BOOL_ARB:
		case GL_BOOL_VEC2_ARB:
		case GL_BOOL_VEC3_ARB:
		case GL_BOOL_VEC4_ARB:
			[uniformXValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]]];
			[uniformXSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn]];
			[uniformXSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:0 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:0 + currentMatrixStride * matrixColumn] + 1)];
			[uniformXSlider setAllowsTickMarkValuesOnly: true];
			if  ([uniformYValue isEnabled]) {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]]];
				[uniformYSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn]];
				[uniformYSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:1 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:1 + currentMatrixStride * matrixColumn] + 1)];
				[uniformYSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformYValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformYSlider setIntValue: 0];
				[uniformYSlider setNumberOfTickMarks:0];
				[uniformYSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformZValue isEnabled]) {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]]];
				[uniformZSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn]];
				[uniformZSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:2 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:2 + currentMatrixStride * matrixColumn] + 1)];
				[uniformZSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformZValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformZSlider setIntValue: 0];
				[uniformZSlider setNumberOfTickMarks:0];
				[uniformZSlider setAllowsTickMarkValuesOnly: false];
			}
			if  ([uniformWValue isEnabled]) {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"%ld", (int)[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]]];
				[uniformWSlider setIntValue: (int)[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]];
				[uniformWSlider setNumberOfTickMarks:([currentUniformValue getMaxValAtIndex:3 + currentMatrixStride * matrixColumn] - [currentUniformValue getMinValAtIndex:3 + currentMatrixStride * matrixColumn] + 1)];
				[uniformWSlider setAllowsTickMarkValuesOnly: true];
			} else {
				[uniformWValue setStringValue:[NSString stringWithFormat:@"0"]];
				[uniformWSlider setIntValue: 0];
				[uniformWSlider setNumberOfTickMarks:0];
				[uniformWSlider setAllowsTickMarkValuesOnly: false];
			}
			if ([glView usingShader])
				[parser setUniformInt: currentUniformValue];
			break;
		default:
			break;
	}
	// ensure color is set on read and select
	if ([uniformColor isEnabled]) {
		// copy to color
		if (currentUniformType == GL_FLOAT_VEC3_ARB || currentUniformType == GL_FLOAT_MAT3_ARB)
			[uniformColor setColor:[NSColor colorWithCalibratedRed:[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn] 
															   green:[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn] 
															   blue:[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn] 
															   alpha:1.0]];
		else
			[uniformColor setColor:[NSColor colorWithCalibratedRed:[currentUniformValue getCurrentValAtIndex:0 + currentMatrixStride * matrixColumn] 
															   green:[currentUniformValue getCurrentValAtIndex:1 + currentMatrixStride * matrixColumn] 
															   blue:[currentUniformValue getCurrentValAtIndex:2 + currentMatrixStride * matrixColumn] 
															   alpha:[currentUniformValue getCurrentValAtIndex:3 + currentMatrixStride * matrixColumn]]];
	}

	[self shaderRedraw];
}

// these are called from the parser with the actual values queried
- (void) setUniformFloatData:(GLfloat *)fVal
{
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_INT:
		case GL_BOOL_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%f)", fVal[0]]];
			break;
		case GL_FLOAT_VEC2_ARB:
		case GL_INT_VEC2_ARB:
		case GL_BOOL_VEC2_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%f, %f)", fVal[0], fVal[1]]];
			break;
		case GL_FLOAT_VEC3_ARB:
		case GL_INT_VEC3_ARB:
		case GL_BOOL_VEC3_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%f, %f, %f)", fVal[0], fVal[1], fVal[2]]];
			break;
		case GL_FLOAT_VEC4_ARB:
		case GL_INT_VEC4_ARB:
		case GL_BOOL_VEC4_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%f, %f, %f, %f)", fVal[0], fVal[1], fVal[2], fVal[3]]];
			break;
		case GL_FLOAT_MAT2_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%0.3f, %0.3f)\n(%0.3f, %0.3f)", fVal[0], fVal[2], fVal[1], fVal[3]]];
			break;
		case GL_FLOAT_MAT3_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%0.3f, %0.3f, %0.3f)\n(%0.3f, %0.3f, %0.3f)\n(%0.3f, %0.3f, %0.3f)", fVal[0], fVal[3], fVal[6], fVal[1], fVal[4], fVal[7], fVal[2], fVal[5], fVal[8]]];
			break;
		case GL_FLOAT_MAT4_ARB:
			[uniformFloatResult setStringValue:[NSString stringWithFormat:@"(%0.3f, %0.3f, %0.3f, %0.3f)\n(%0.3f, %0.3f, %0.3f, %0.3f)\n(%0.3f, %0.3f, %0.3f, %0.3f)\n(%0.3f, %0.3f, %0.3f, %0.3f)", fVal[0], fVal[4], fVal[8], fVal[12], fVal[1], fVal[5], fVal[9], fVal[13], fVal[2], fVal[6], fVal[10], fVal[14], fVal[3], fVal[7], fVal[11], fVal[15]]];
			break;
		default:
			break;
	}
} 

- (void) setUniformIntData:(GLint *)iVal
{
	switch (currentUniformType) { // get type in text form
		case GL_FLOAT: 
		case GL_INT:
		case GL_BOOL_ARB:
		case GL_SAMPLER_1D_ARB:
		case GL_SAMPLER_2D_ARB:
		case GL_SAMPLER_3D_ARB:
		case GL_SAMPLER_CUBE_ARB:
		case GL_SAMPLER_1D_SHADOW_ARB:
		case GL_SAMPLER_2D_SHADOW_ARB:
		case GL_SAMPLER_2D_RECT_ARB:
		case GL_SAMPLER_2D_RECT_SHADOW_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld)", iVal[0]]];
			break;
		case GL_FLOAT_VEC2_ARB:
		case GL_INT_VEC2_ARB:
		case GL_BOOL_VEC2_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld)", iVal[0], iVal[1]]];
			break;
		case GL_FLOAT_VEC3_ARB:
		case GL_INT_VEC3_ARB:
		case GL_BOOL_VEC3_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld, %ld)", iVal[0], iVal[1], iVal[2]]];
			break;
		case GL_FLOAT_VEC4_ARB:
		case GL_INT_VEC4_ARB:
		case GL_BOOL_VEC4_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld, %ld, %ld)", iVal[0], iVal[1], iVal[2], iVal[3]]];
			break;
		case GL_FLOAT_MAT2_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld)\n(%ld, %ld)", iVal[0], iVal[2], iVal[1], iVal[3]]];
			break;
		case GL_FLOAT_MAT3_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld, %ld)\n(%ld, %ld, %ld)\n(%ld, %ld, %ld)", iVal[0], iVal[3], iVal[6], iVal[1], iVal[4], iVal[7], iVal[2], iVal[5], iVal[8]]];
			break;
		case GL_FLOAT_MAT4_ARB:
			[uniformIntResult setStringValue:[NSString stringWithFormat:@"(%ld, %ld, %ld, %ld)\n(%ld, %ld, %ld, %ld)\n(%ld, %ld, %ld, %ld)\n(%ld, %ld, %ld, %ld)",
											  iVal[0], iVal[4], iVal[8], iVal[12], iVal[1], iVal[5], iVal[9], iVal[13], iVal[2], iVal[6], iVal[10], iVal[14], iVal[3], iVal[7], iVal[11], iVal[15]]];
			break;
		default:
			break;
	}
} 

//LIGHTS
- (void)lightUpdate:(GLenum*)pLight:(GLenum*)pValueField
{
	*pLight=GL_LIGHT0+[lightsNum indexOfSelectedItem];

	//get value field to fill in
	GLenum valueField[]={GL_AMBIENT,GL_DIFFUSE,GL_SPECULAR,GL_POSITION,GL_SPOT_DIRECTION,GL_SPOT_EXPONENT,GL_SPOT_CUTOFF,GL_CONSTANT_ATTENUATION,GL_LINEAR_ATTENUATION,GL_QUADRATIC_ATTENUATION};
	*pValueField=valueField[[lightsValues indexOfSelectedItem]];
}
- (void)lightFixValues
{
	GLenum light;
	GLenum valueField;
	[self lightUpdate:&light:&valueField];

	[lightOn setState:glIsEnabled(light)];

	GLfloat params[4]={0.0,0.0,0.0,0.0};

	glGetLightfv(light,valueField,params);

	//get values fill in
	[lightXValue setFloatValue:params[0]];
	[lightYValue setFloatValue:params[1]];
	[lightZValue setFloatValue:params[2]];
	[lightWValue setFloatValue:params[3]];
}
- (IBAction)lightEnableChange:(id)sender
{
	if([lightsEnable state]) // if we are lighting...
	{
		glEnable(GL_LIGHTING);
		/*[lightsNum setEnabled:true];
		[lightsValues setEnabled:true];
		[lightXValue setEnabled:true];
		[lightYValue setEnabled:true];
		[lightZValue setEnabled:true];
		[lightWValue setEnabled:true];
		[lightOn setEnabled:true];
		[lightOn setState:false];*/
	}
	else
	{
		/*glDisable(GL_LIGHT0);
		glDisable(GL_LIGHT1);
		glDisable(GL_LIGHT2);
		glDisable(GL_LIGHT3);
		glDisable(GL_LIGHT4);
		glDisable(GL_LIGHT5);
		glDisable(GL_LIGHT6);
		glDisable(GL_LIGHT7);*/

		glDisable(GL_LIGHTING);
		/*[lightsNum setEnabled:false];
		[lightsValues setEnabled:false];
		[lightXValue setEnabled:false];
		[lightYValue setEnabled:false];
		[lightZValue setEnabled:false];
		[lightWValue setEnabled:false];
		[lightOn setEnabled:false];*/
	}
	[glView setNeedsDisplay: YES];
	[self lightFixValues];
}
- (IBAction)lightNumChange:(id)sender
{
	[self lightFixValues];
	[lightsPreset selectItemAtIndex:0];//custom
}
- (IBAction)lightTypeChange:(id)sender
{
	[self lightFixValues];
}
- (IBAction)lightValueChange:(id)sender
{
	GLenum light;
	GLenum valueField;
	GLfloat params[4]={0.0,0.0,0.0,0.0};

	[self lightUpdate:&light:&valueField];

	//set new values
	params[0]=[lightXValue floatValue];
	params[1]=[lightYValue floatValue];
	params[2]=[lightZValue floatValue];
	params[3]=[lightWValue floatValue];

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glLightfv(light,valueField,params);

	[lightsPreset selectItemAtIndex:0];//custom
	[glView setNeedsDisplay: YES];
}
- (IBAction)lightToggle:(id)sender;
{
	GLenum light;
	GLenum valueField;

	[self lightUpdate:&light:&valueField];
	if([lightOn state])
	{
		glEnable(light);
	}
	else
	{
		glDisable(light);
	}

	[glView setNeedsDisplay: YES];
}
- (void)lightReset:(GLenum)light
{
	GLenum valueField[]={GL_AMBIENT,GL_DIFFUSE,GL_SPECULAR,GL_POSITION,GL_SPOT_DIRECTION,GL_SPOT_EXPONENT,GL_SPOT_CUTOFF,GL_CONSTANT_ATTENUATION,GL_LINEAR_ATTENUATION,GL_QUADRATIC_ATTENUATION};
	int field;
	for(field=0;field<sizeof(valueField)/sizeof(valueField[0]);field++)
	{
		GLfloat params[4]={0.0,0.0,0.0,0.0};
	
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	
		glLightfv(light,valueField[field],params);
	}
}
- (IBAction)lightsResetLight:(id)sender
{
	GLenum light;
	GLenum valueField;

	[self lightUpdate:&light:&valueField];

	[self lightReset:light];

	[self lightFixValues];
	[lightsPreset selectItemAtIndex:0];//custom
	[glView setNeedsDisplay: YES];
}
- (IBAction)lightsReset:(id)sender
{
	GLenum light;
	for(light=GL_LIGHT0;light<=GL_LIGHT7;light++)
	{
		[self lightReset:light];
	}

	[self lightFixValues];
	[lightsPreset selectItemAtIndex:0];//custom
	[glView setNeedsDisplay: YES];
}
- (IBAction)lightsPreset:(id)sender
{
	GLenum light;
	GLenum valueField;

	[self lightUpdate:&light:&valueField];

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	switch([lightsPreset indexOfSelectedItem])
	{
	case 0://custom
		break;
	case 1://ambient
		{valueField=GL_AMBIENT;					GLfloat params[4]={0.5,0.5,0.5,0.5};	glLightfv(light,valueField,params);}
		{valueField=GL_DIFFUSE;					GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPECULAR;				GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_POSITION;				GLfloat params[4]={0.0,0.0,1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_DIRECTION;			GLfloat params[4]={0.0,0.0,-1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_EXPONENT;			GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_CUTOFF;				GLfloat params[4]={180.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_CONSTANT_ATTENUATION;	GLfloat params[4]={1.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_LINEAR_ATTENUATION;		GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_QUADRATIC_ATTENUATION;	GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		break;
	case 2://directional
		{valueField=GL_AMBIENT;					GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_DIFFUSE;					GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPECULAR;				GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_POSITION;				GLfloat params[4]={0.0,0.0,1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_DIRECTION;			GLfloat params[4]={0.0,0.0,-1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_EXPONENT;			GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_CUTOFF;				GLfloat params[4]={180.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_CONSTANT_ATTENUATION;	GLfloat params[4]={1.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_LINEAR_ATTENUATION;		GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_QUADRATIC_ATTENUATION;	GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		break;
	case 3://point
		{valueField=GL_AMBIENT;					GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_DIFFUSE;					GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPECULAR;				GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_POSITION;				GLfloat params[4]={0.0,0.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_DIRECTION;			GLfloat params[4]={0.0,0.0,-1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_EXPONENT;			GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_CUTOFF;				GLfloat params[4]={180.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_CONSTANT_ATTENUATION;	GLfloat params[4]={1.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_LINEAR_ATTENUATION;		GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_QUADRATIC_ATTENUATION;	GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		break;
	case 4://spot
		{valueField=GL_AMBIENT;					GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_DIFFUSE;					GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPECULAR;				GLfloat params[4]={1.0,1.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_POSITION;				GLfloat params[4]={0.0,0.0,1.0,1.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_DIRECTION;			GLfloat params[4]={0.0,0.0,-1.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_EXPONENT;			GLfloat params[4]={64.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_SPOT_CUTOFF;				GLfloat params[4]={2.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_CONSTANT_ATTENUATION;	GLfloat params[4]={1.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_LINEAR_ATTENUATION;		GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		{valueField=GL_QUADRATIC_ATTENUATION;	GLfloat params[4]={0.0,0.0,0.0,0.0};	glLightfv(light,valueField,params);}
		break;
	default:
		break;
	}
	[self lightFixValues];
	[glView setNeedsDisplay: YES];
}
//lights done

//FOG
- (void)fogUpdate:(GLenum*)pValueField
{
	//get value field to fill in
	GLenum valueField[]={GL_FOG_COLOR,GL_FOG_DENSITY,GL_FOG_START,GL_FOG_END};
	*pValueField=valueField[[fogValues indexOfSelectedItem]];
}
- (void)fogFixValues
{
	GLenum valueField;
	[self fogUpdate:&valueField];

	GLfloat params[4]={0.0,0.0,0.0,0.0};

	glGetFloatv(valueField,params);

	//get values fill in
	[fogXValue setFloatValue:params[0]];
	[fogYValue setFloatValue:params[1]];
	[fogZValue setFloatValue:params[2]];
	[fogWValue setFloatValue:params[3]];
}
- (IBAction)fogEnableChange:(id)sender
{
	if([fogEnable state]) // if we are lighting...
	{
		glEnable(GL_FOG);
	}
	else
	{
		glDisable(GL_FOG);
	}
	[glView setNeedsDisplay: YES];
	[self fogFixValues];
}
- (IBAction)fogTypeChange:(id)sender
{
	[self fogFixValues];
}
- (IBAction)fogValueChange:(id)sender
{
	GLenum valueField;
	GLfloat params[4]={0.0,0.0,0.0,0.0};

	[self fogUpdate:&valueField];

	//set new values
	params[0]=[fogXValue floatValue];
	params[1]=[fogYValue floatValue];
	params[2]=[fogZValue floatValue];
	params[3]=[fogWValue floatValue];

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glFogfv(valueField,params);

	[glView setNeedsDisplay: YES];
}
//fog done

- (IBAction)autoLink:(id)sender
{
	if ([autoLinkButton state]) // if we are auto linking...
		[self link:self];
}

- (IBAction)link:(id)sender
{
	if (!terminating)
		[parser link];
}

- (NSTextField *) linkResultTextField
{
	return linkResultText;
}

- (IBAction)animateToggle:(id)sender
{
	[glView animate:[sender state]];
}

- (IBAction)floatRendererToggle:(id)sender;
{
	[glView setFloatRenderer:[sender state]];
}

- (BOOL) usingShaderPraogram;
{
	return [glView usingShader];
}

- (IBAction)objectToggle:(id)sender;
{
	[glView object:[objectPopUp indexOfSelectedItem]];
}

- (void)shaderRedraw
{
	if ([glView usingShader])
		[glView setNeedsDisplay: YES];
}

- (void)useShader
{
	if ([useShaderButton state])
		[glView useShader:[parser getLinkedProgram]];
	else
		[glView useShader:NULL];
	if ([unformPullDown isEnabled]) { // need to set all values here...
		int i;
		// first set all the unform values...  (need to walk menu and set)
		for (i = 0; i < [unformPullDown numberOfItems]; i++) {
			[parser setCurrentUniform:i]; // set every item in turn
		}
		// finally set selected uniform...
		[parser setCurrentUniform:[unformPullDown indexOfSelectedItem]]; 
	}
}

- (IBAction)useShaderToggle:(id)sender
{
	[self useShader];
}


- (IBAction)textureImageDropped:(id)sender;
{
//NSLog (@"Drop texture image");
	// this also makes the unit the first responder
	int textureUnitIndex;
	NSImageView *imageView;
	
	textureUnitIndex = 0;
	imageView = (NSImageView *)sender;
	
	if (imageView == textureUnit0ImageView)
		textureUnitIndex = 0;
	else if (imageView == textureUnit1ImageView)
		textureUnitIndex = 1;
	else if (imageView == textureUnit2ImageView)
		textureUnitIndex = 2;
	else if (imageView == textureUnit3ImageView)
		textureUnitIndex = 3;
	else if (imageView == textureUnit4ImageView)
		textureUnitIndex = 4;
	else if (imageView == textureUnit5ImageView)
		textureUnitIndex = 5;
	else if (imageView == textureUnit6ImageView)
		textureUnitIndex = 6;
	else if (imageView == textureUnit7ImageView)
		textureUnitIndex = 7;

	NSImage *image = [imageView image];
	if (image) {
		textureOriginalSizes[textureUnitIndex] = [image size];
		textureTarget[textureUnitIndex] = (GLenum)[[textureTargetPopUp selectedItem]tag]; 
		[image setScalesWhenResized: YES];
		if (GL_TEXTURE_2D == textureTarget[textureUnitIndex]) {
			// set size to power of two...
			int width = (int)[image size].width;
			int height = (int)[image size].height;
			int i = 0;
			while (width) {
				width = width >> 1; 
				i++;
			} 

			width = 1 << (i - 1); 
			i = 0;
			while (height) {
				height = height >> 1; 
				i++;
			}
			height = 1 << (i - 1);
			// this truncates and does not scale...
			[image setSize:NSMakeSize((float)width, (float)height)];
		}
	}	
	[self changeFirstResponder:(NSResponder *)imageView];
	[glView useImageAsTexture:image forUnit:textureUnitIndex withTarget:textureTarget[textureUnitIndex]];
	[glView setNeedsDisplay: YES];
}

- (void) changeFirstResponder:(NSResponder *)aResponder;
{
//NSLog (@"Select texture image");

	int textureUnitIndex;
	NSImageView *imageView;
	
	textureUnitIndex = -1;
	imageView = (NSImageView *)aResponder;
	
	if (imageView == textureUnit0ImageView)
		textureUnitIndex = 0;
	else if (imageView == textureUnit1ImageView)
		textureUnitIndex = 1;
	else if (imageView == textureUnit2ImageView)
		textureUnitIndex = 2;
	else if (imageView == textureUnit3ImageView)
		textureUnitIndex = 3;
	else if (imageView == textureUnit4ImageView)
		textureUnitIndex = 4;
	else if (imageView == textureUnit5ImageView)
		textureUnitIndex = 5;
	else if (imageView == textureUnit6ImageView)
		textureUnitIndex = 6;
	else if (imageView == textureUnit7ImageView)
		textureUnitIndex = 7;
	
	if (-1 < textureUnitIndex && [imageView image]) {
		[textureTargetPopUp setEnabled:true];
		[textureSize setStringValue:[NSString stringWithFormat:@"%d x %d", (int)[[imageView image] size].width, (int)[[imageView image] size].height]];
		[textureOriginalSize setStringValue:[NSString stringWithFormat:@"%d x %d", (int)textureOriginalSizes[textureUnitIndex].width, (int)textureOriginalSizes[textureUnitIndex].height]];
		[textureTargetPopUp selectItemAtIndex:[textureTargetPopUp indexOfItemWithTag:textureTarget[textureUnitIndex]]];
	} else {
		// clear fields
		[textureSize setStringValue:@"NA"];
		[textureOriginalSize setStringValue:@"NA"];
		// dim type control
		[textureTargetPopUp setEnabled:false];
	}
}

-(IBAction) changeTextureTarget: (id) sender
{
	// get current first responder
	NSResponder *aResponder = [[tabView window] firstResponder];
	int textureUnitIndex;
	NSImageView *imageView;
	
	textureUnitIndex = -1;
	imageView = (NSImageView *)aResponder;
	
	if (imageView == textureUnit0ImageView)
		textureUnitIndex = 0;
	else if (imageView == textureUnit1ImageView)
		textureUnitIndex = 1;
	else if (imageView == textureUnit2ImageView)
		textureUnitIndex = 2;
	else if (imageView == textureUnit3ImageView)
		textureUnitIndex = 3;
	else if (imageView == textureUnit4ImageView)
		textureUnitIndex = 4;
	else if (imageView == textureUnit5ImageView)
		textureUnitIndex = 5;
	else if (imageView == textureUnit6ImageView)
		textureUnitIndex = 6;
	else if (imageView == textureUnit7ImageView)
		textureUnitIndex = 7;
	
	if (-1 < textureUnitIndex && [imageView image]) {
		textureTarget[textureUnitIndex] = (GLenum)[[textureTargetPopUp selectedItem]tag];
		// set sizes as needed
		[[imageView image] setSize:textureOriginalSizes[textureUnitIndex]];
		if (GL_TEXTURE_2D == textureTarget[textureUnitIndex]) {
			// set size to power of two...
			int width = (int)[[imageView image] size].width;
			int height = (int)[[imageView image] size].height;
			int i = 0;
			while (width) {
				width = width >> 1; 
				i++;
			} 

			width = 1 << (i - 1); 
			i = 0;
			while (height) {
				height = height >> 1; 
				i++;
			}
			height = 1 << (i - 1);
			// this truncates and does not scale...
			[[imageView image] setSize:NSMakeSize((float)width, (float)height)];
		}
		[textureSize setStringValue:[NSString stringWithFormat:@"%d x %d", (int)[[imageView image] size].width, (int)[[imageView image] size].height]];
		[glView useImageAsTexture:[imageView image] forUnit:textureUnitIndex withTarget:textureTarget[textureUnitIndex]];
		[glView setNeedsDisplay: YES];
	}
}


- (void)setCurrent // ensure the gl context is initialized and current
{
	[[glView openGLContext] makeCurrentContext];
}

- (void)setLinkText:(NSString *)string 
{
	[linkResultText setStringValue:string];
}

- (id)init
{
    if( self = [super init] )
    {
		[[NSNotificationCenter defaultCenter] addObserver:self
							selector:@selector(willTerminate:)
							name:NSApplicationWillTerminateNotification
							object:nil];
    }
    return self;
}

- (void) addUniformWithTitle:(NSString *)title // looks in uniformValues dict for key, adds if not there, setting default min and max
{
	uniformValue * value = [uniformValues objectForKey:title]; // look for uniform name in dictionary
	if (!value) { // if not found
		int i;
		value = [[uniformValue alloc] init]; // create object
		for (i = 0; i < 16; i++) { // initialize values
			[value setCurrentVal:0.0f atIndex:i];
			[value setMinVal:0.0f atIndex:i];
			[value setMaxVal:1.0f atIndex:i];
		}
		[uniformValues setObject:value forKey:title]; // add to dictionary
	}
}

-(void) disableUniforms
{
	if (![useShaderButton state])
		[uniformStatus setStringValue:@"--- Shader not in use, uniforms can't be set. ---"];
	else
		[uniformStatus setStringValue:@" "];
		
	[uniformInfo setStringValue:@" "];
	
	[uniformXValue setStringValue:@"---"];
	[uniformYValue setStringValue:@"---"];
	[uniformZValue setStringValue:@"---"];
	[uniformWValue setStringValue:@"---"];
	[uniformXMin setStringValue:@"---"];
	[uniformYMin setStringValue:@"---"];
	[uniformZMin setStringValue:@"---"];
	[uniformWMin setStringValue:@"---"];
	[uniformXMax setStringValue:@"---"];
	[uniformYMax setStringValue:@"---"];
	[uniformZMax setStringValue:@"---"];
	[uniformWMax setStringValue:@"---"];
	[uniformXValue setEnabled:false];
	[uniformXMin setEnabled:false];
	[uniformXMax setEnabled:false];
	[uniformXSlider setEnabled:false];
	[uniformYValue setEnabled:false];
	[uniformYMin setEnabled:false];
	[uniformYMax setEnabled:false];
	[uniformYSlider setEnabled:false];
	[uniformZValue setEnabled:false];
	[uniformZMin setEnabled:false];
	[uniformZMax setEnabled:false];
	[uniformZSlider setEnabled:false];
	[uniformWValue setEnabled:false];
	[uniformWMin setEnabled:false];
	[uniformWMax setEnabled:false];
	[uniformWSlider setEnabled:false];

	[uniformColumnPopUp setEnabled:false];

	[uniformColor setEnabled:false];
	[uniformIntResult setStringValue:@"---"];
	[uniformFloatResult setStringValue:@"---"];
}

- (void)finishInit:(NSTimer *)theTimer
{
	[forceFloatRendererButton setState: NSOffState]; // ensures the initialization works correctly
	[glView setFloatRenderer:[forceFloatRendererButton state]];
}

- (void) awakeFromNib
{
	NSUserDefaults *defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
    // init fonts for use with strings
	[linkResultText setStringValue:@"Not linked"];

 	if (!resultsString) {
		[self setResultsString :@"----"];
	}
	if (!logString) {
		[self setLogString :@"----"];
	}
	
	matrixColumn = 0;
	currentMatrixStride = 0;
	[resultsTextView setFont:[NSFont fontWithName: @"Monaco" size:9]];
	[logTextView setFont:[NSFont fontWithName: @"Monaco" size:9]];
	[self updateResultsView];
	[glslSupportText setTextColor:[NSColor colorWithCalibratedRed:0.5f green:0.0f blue:0.0f alpha:1.0f]]; // set color for failure case
	// ensure OpenGL is setup
	[forceFloatRendererButton setState: NSOnState]; // ensures the initialization works correctly
	[glView setFloatRenderer:[forceFloatRendererButton state]];
	[[glView openGLContext] makeCurrentContext];
	[glView prepareOpenGL];
	[glView object:[objectPopUp indexOfSelectedItem]];
	[glView animate:[animateButton state]];
	[glView object:[objectPopUp indexOfSelectedItem]];
	[uniformXSlider setContinuous:true];
	[uniformYSlider setContinuous:true];
	[uniformZSlider setContinuous:true];
	[uniformWSlider setContinuous:true];
	[NSColor setIgnoresAlpha:NO];
	[unformPullDown removeAllItems];
	[self setNumUniforms:[unformPullDown numberOfItems]];
	[unformPullDown addItemWithTitle:@"No Uniforms"];
	[unformPullDown setEnabled:false];
	[self disableUniforms];

	
    NSData *defaultsData = [[NSUserDefaults standardUserDefaults] dataForKey:gUniformValueKey];
	if ([defaultsData length])
		uniformValues = [[NSUnarchiver unarchiveObjectWithData:defaultsData] mutableCopy];
	else // no defaults found, init empty uniforms
		uniformValues = [[NSMutableDictionary alloc] init];
		
	[textureUnit0ImageView setImage:[NSImage imageNamed:@"EarthMap_256"]];
	[self textureImageDropped:textureUnit0ImageView];
	
	[NSTimer scheduledTimerWithTimeInterval:0.00 target:self selector:@selector(finishInit:)  userInfo:nil repeats:NO];

	///IBOutlet NSButton* lightsEnable;//on or off -- GL_LIGHTING
	////IBOutlet NSPopUpButton* lightsType;//ambient,directional,point,spot -- 
	//IBOutlet NSPopUpButton* lightsNum;//GL_LIGHT0,GL_LIGHT1,GL_LIGHT2,GL_LIGHT3,...
	//IBOutlet NSPopUpButton* lightsValues;//GL_AMBIENT(4),GL_DIFFUSE(4),GL_SPECULAR(4),GL_POSITION(4),GL_SPOT_DIRECTION(3),GL_SPOT_EXPONENT(1),GL_SPOT_CUTOFF(1)
	//IBOutlet NSFormCell* lightXValue;
	//IBOutlet NSFormCell* lightYValue;
	//IBOutlet NSFormCell* lightZValue;
	//IBOutlet NSFormCell* lightWValue;

	//[self lightEnableChange];
	//[self lightNumChange];
	//[self lightTypeChange];
	//[self lightValueChange];
}

+(void) initialize 
{
//	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
//	[[NSUserDefaults standardUserDefaults] setObject:[NSData data] forKey:gUniformValueKey];
//	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void) invalidateObjects // called to invalidate all shader and program objects on renderer change
{
	NSDocument * doc = nil;
	NSEnumerator * docEnumerator = nil;
	// Initialize the window enumerator
	// initially set shader to not be used...
	[parser invalidateProgram];
	docEnumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
	// Loop through all windows
	while (doc = [docEnumerator nextObject]) {
		if ([doc respondsToSelector:@selector(invalidateShader)])
			[(MyDocument*)doc invalidateShader];
	}
	if ([useShaderButton state])
		[glView useShader:[parser getLinkedProgram]];
	if ([unformPullDown isEnabled]) { // need to set all values here...
		int i;
		// first set all the unform values...  (need to walk menu and set)
		for (i = 0; i < [unformPullDown numberOfItems]; i++) {
			[parser setCurrentUniform:i]; // set every item in turn
		}
		// finally set selected uniform...
		[parser setCurrentUniform:[unformPullDown indexOfSelectedItem]]; 
	}
}

@end
