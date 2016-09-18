//
//  MyDocument.m
//  GL2Parser
//

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

  Created by on Fri Dec 12 2003.
  Copyright (c) 2003-2005 Apple Computer, Inc., All Rights Reserved

*/

#include <stdlib.h>

#import "MyDocument.h"
#import "GLSLParser.h"

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import <OpenGL/OpenGL.h>


@implementation MyDocument 

static GLSLParser * parser;

+ (void) setParser:(GLSLParser *)globalParser;
{
	parser = globalParser;
} 

// -----

- (NSString *)originalString 
{
	return originalString;
}

- (void) setOriginalString:(NSString *)value
{
	[value retain];
	[originalString release];
	originalString = value;
}

- (void) updateOriginalString
{
	[self setOriginalString: [originalTextView string]];
}

- (void) updateOriginalView
{
	[originalTextView setString: [self originalString]];
}

// -----

- (NSString *)logString 
{
	return [logTextView string];
}

- (void) setLogString:(NSAttributedString *)value
{
	[[logTextView textStorage] beginEditing];
	[[logTextView textStorage] setAttributedString:value];
	[[logTextView textStorage] endEditing];
}

- (void) appendLogString:(NSAttributedString *)value
{
	[[logTextView textStorage] beginEditing];
	[[logTextView textStorage] appendAttributedString:value];
	[[logTextView textStorage] endEditing];
}

- (void) clearLogString
{
	NSAttributedString * string = [[NSAttributedString alloc] initWithString:@"" attributes:stanStringAttrib];
	[[logTextView textStorage] beginEditing];
	[self setLogString:string];
	[[logTextView textStorage] endEditing];
	[string release];
}

// -----

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}
 
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void) windowWillClose:(id) sender
{
     printf( "windowWillClose\n" );
	[super windowWillClose:sender];
}

- (void) buildSyntaxDictionary
{
	keyWords = [[NSMutableDictionary alloc] init];
	colorComments = [[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0] retain];
	colorKeywords = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.7 alpha: 1.0];
	colorReserved = [NSColor colorWithCalibratedRed: 0.7 green: 0.0 blue: 0.0 alpha: 1.0];
	colorDatatypes = [NSColor colorWithCalibratedRed: 0.0 green: 0.4 blue: 0.0 alpha: 1.0];
	colorBuiltInFunctions = [NSColor colorWithCalibratedRed: 0.4 green: 0.0 blue: 0.4 alpha: 1.0];
	colorBuiltInVariables = [NSColor colorWithCalibratedRed: 0.50 green: 0.20 blue: 0.0 alpha: 1.0];
	colorBuiltInConstants = [NSColor colorWithCalibratedRed: 0.0 green: 0.4 blue: 0.4 alpha: 1.0];
	colorPreProcessor = [NSColor colorWithCalibratedRed: 0.3 green: 0.0 blue: 0.0 alpha: 1.0];

	[keyWords setObject: colorKeywords forKey: @"attribute"];
	[keyWords setObject: colorKeywords forKey: @"const"];
	[keyWords setObject: colorKeywords forKey: @"uniform"];
	[keyWords setObject: colorKeywords forKey: @"varying"];
	[keyWords setObject: colorKeywords forKey: @"break"];
	[keyWords setObject: colorKeywords forKey: @"continue"];
	[keyWords setObject: colorKeywords forKey: @"do"];
	[keyWords setObject: colorKeywords forKey: @"for"];
	[keyWords setObject: colorKeywords forKey: @"while"];
	[keyWords setObject: colorKeywords forKey: @"if"];
	[keyWords setObject: colorKeywords forKey: @"else"];
	[keyWords setObject: colorKeywords forKey: @"in"];
	[keyWords setObject: colorKeywords forKey: @"out"];
	[keyWords setObject: colorKeywords forKey: @"inout"];
	[keyWords setObject: colorKeywords forKey: @"true"];
	[keyWords setObject: colorKeywords forKey: @"false"];
	[keyWords setObject: colorKeywords forKey: @"discard"];
	[keyWords setObject: colorKeywords forKey: @"return"];
	// reserved words
	[keyWords setObject: colorReserved forKey: @"asm"];
	[keyWords setObject: colorReserved forKey: @"class"];
	[keyWords setObject: colorReserved forKey: @"union"];
	[keyWords setObject: colorReserved forKey: @"enum"];
	[keyWords setObject: colorReserved forKey: @"typedef"];
	[keyWords setObject: colorReserved forKey: @"template"];
	[keyWords setObject: colorReserved forKey: @"switch"];
	[keyWords setObject: colorReserved forKey: @"default"];
	[keyWords setObject: colorReserved forKey: @"inline"];
	[keyWords setObject: colorReserved forKey: @"noinline"];
	[keyWords setObject: colorReserved forKey: @"volatile"];
	[keyWords setObject: colorReserved forKey: @"public"];
	[keyWords setObject: colorReserved forKey: @"static"];
	[keyWords setObject: colorReserved forKey: @"extern"];
	[keyWords setObject: colorReserved forKey: @"external"];
	[keyWords setObject: colorReserved forKey: @"interface"];
	[keyWords setObject: colorReserved forKey: @"input"];
	[keyWords setObject: colorReserved forKey: @"output"];
	[keyWords setObject: colorReserved forKey: @"sizeof"];
	[keyWords setObject: colorReserved forKey: @"cast"];
	[keyWords setObject: colorReserved forKey: @"namespace"];
	[keyWords setObject: colorReserved forKey: @"using"];

	[keyWords setObject: colorDatatypes forKey: @"float"];
	[keyWords setObject: colorDatatypes forKey: @"int"];
	[keyWords setObject: colorDatatypes forKey: @"void"];
	[keyWords setObject: colorDatatypes forKey: @"bool"];
	[keyWords setObject: colorDatatypes forKey: @"mat2"];
	[keyWords setObject: colorDatatypes forKey: @"mat3"];
	[keyWords setObject: colorDatatypes forKey: @"mat4"];
	[keyWords setObject: colorDatatypes forKey: @"vec2"];
	[keyWords setObject: colorDatatypes forKey: @"vec3"];
	[keyWords setObject: colorDatatypes forKey: @"vec4"];
	[keyWords setObject: colorDatatypes forKey: @"ivec2"];
	[keyWords setObject: colorDatatypes forKey: @"ivec3"];
	[keyWords setObject: colorDatatypes forKey: @"ivec4"];
	[keyWords setObject: colorDatatypes forKey: @"bvec2"];
	[keyWords setObject: colorDatatypes forKey: @"bvec3"];
	[keyWords setObject: colorDatatypes forKey: @"bvec4"];
	[keyWords setObject: colorDatatypes forKey: @"sampler1D"];
	[keyWords setObject: colorDatatypes forKey: @"sampler2D"];
	[keyWords setObject: colorDatatypes forKey: @"sampler3D"];
	[keyWords setObject: colorDatatypes forKey: @"samplerCube"];
	[keyWords setObject: colorDatatypes forKey: @"sampler1DShadow"];
	[keyWords setObject: colorDatatypes forKey: @"sampler2DShadow"];
	[keyWords setObject: colorDatatypes forKey: @"struct"];

	[keyWords setObject: colorReserved forKey: @"hvec2"];
	[keyWords setObject: colorReserved forKey: @"hvec3"];
	[keyWords setObject: colorReserved forKey: @"hvec4"];
	[keyWords setObject: colorReserved forKey: @"dvec2"];
	[keyWords setObject: colorReserved forKey: @"dvec3"];
	[keyWords setObject: colorReserved forKey: @"dvec4"];
	[keyWords setObject: colorReserved forKey: @"fvec2"];
	[keyWords setObject: colorReserved forKey: @"fvec3"];
	[keyWords setObject: colorReserved forKey: @"fvec4"];
	[keyWords setObject: colorReserved forKey: @"sampler2DRect"];
	[keyWords setObject: colorReserved forKey: @"sampler3DRect"];
	[keyWords setObject: colorReserved forKey: @"sampler2DRectShadow"];
	[keyWords setObject: colorReserved forKey: @"long"];
	[keyWords setObject: colorReserved forKey: @"short"];
	[keyWords setObject: colorReserved forKey: @"double"];
	[keyWords setObject: colorReserved forKey: @"half"];
	[keyWords setObject: colorReserved forKey: @"fixed"];
	[keyWords setObject: colorReserved forKey: @"unsigned"];

	[keyWords setObject: colorBuiltInFunctions forKey: @"degrees"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"radians"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"sin"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"cos"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"tan"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"asin"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"acos"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"atan"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"pow"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"exp"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"log"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"exp2"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"log2"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"sqrt"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"inversesqrt"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"abs"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"sign"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"floor"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"ceil"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"fract"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"mod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"min"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"max"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"clamp"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"mix"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"step"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"smoothstep"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"length"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"distance"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"dot"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"cross"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"normalize"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"ftransform"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"faceforward"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"reflect"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"refract"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"matrixCompMult"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"lessThan"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"lessThanEqual"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"greaterThan"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"greaterThanEqual"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"equal"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"notEqual"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"any"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"all"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"not"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture1D"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture1DProj"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture1DLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture1DProjLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture2D"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture2DProj"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture2DLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture2DProjLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture3D"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture3DProj"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture3DLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"texture3DProjLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"textureCube"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"textureCubeLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow1D"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow1DProj"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow1DLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow1DProjLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow2D"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow2DProj"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow2DLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"shadow2DProjLod"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"dFdx"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"dFdy"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"fwidth"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"noise1"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"noise2"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"noise3"];
	[keyWords setObject: colorBuiltInFunctions forKey: @"noise4"];
	
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_BackColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontSecondaryColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_BackSecondaryColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TexCoord"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FogFragCoord"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Color"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_SecondaryColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Normal"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Vertex"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord0"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord1"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord2"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord3"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord4"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord5"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord6"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_MultiTexCoord7"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FogCoord"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewMatrix"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ProjectionMatrix"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewProjectionMatrix"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TextureMatrix"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_NormalMatrix"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewMatrixInverse"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ProjectionMatrixInverse"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewProjectionMatrixInverse"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TextureMatrixInverse"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewMatrixTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ProjectionMatrixTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewProjectionMatrixTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TextureMatrixTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewMatrixInverseTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ProjectionMatrixInverseTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ModelViewProjectionMatrixInverseTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TextureMatrixInverseTranspose"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_NormalScale"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_DepthRange"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ClipPlane"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Point"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontMaterial"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_BackMaterial"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_LightSource"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_LightModel"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontLightModelProduct"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_BackLightModelProduct"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontLightProduct"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_BackLightProduct"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_TextureEnvColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_EyePlaneQ"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_EyePlaneS"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_EyePlaneT"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_EyePlaneR"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ObjectPlaneQ"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ObjectPlaneS"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ObjectPlaneT"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ObjectPlaneR"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Fog"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FrontFacing"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FragCoord"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FragColor"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FragDepth"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_FragData"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_Position"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_PointSize"];
	[keyWords setObject: colorBuiltInVariables forKey: @"gl_ClipVertex"];

	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxLights"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxClipPlanes"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxTextureUnits"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxTextureCoords"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxVertexAttribs"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxVertexUniformComponents"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxVaryingFloats"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxVertexTextureImageUnits"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxCombinedTextureImageUnits"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxTextureImageUnits"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxFragmentUniformComponents"];
	[keyWords setObject: colorBuiltInConstants forKey: @"gl_MaxDrawBuffers"];

	[keyWords setObject: colorPreProcessor forKey: @"#"];
	[keyWords setObject: colorPreProcessor forKey: @"#define"];
	[keyWords setObject: colorPreProcessor forKey: @"#undef"];
	[keyWords setObject: colorPreProcessor forKey: @"#if"];
	[keyWords setObject: colorPreProcessor forKey: @"#ifdef"];
	[keyWords setObject: colorPreProcessor forKey: @"#ifndef"];
	[keyWords setObject: colorPreProcessor forKey: @"#else"];
	[keyWords setObject: colorPreProcessor forKey: @"#elif"];
	[keyWords setObject: colorPreProcessor forKey: @"#endif"];
	[keyWords setObject: colorPreProcessor forKey: @"#error"];
	[keyWords setObject: colorPreProcessor forKey: @"#pragma"];
	[keyWords setObject: colorPreProcessor forKey: @"#extension"];
	[keyWords setObject: colorPreProcessor forKey: @"#version"];
	[keyWords setObject: colorPreProcessor forKey: @"#line"];
	[keyWords setObject: colorPreProcessor forKey: @"__LINE__"];
	[keyWords setObject: colorPreProcessor forKey: @"__FILE__"];
	[keyWords setObject: colorPreProcessor forKey: @"__VERSION_"];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	NSString * typeString;
    [super windowControllerDidLoadNib:aController];
	
	// build syntax highlighting dictionry
	[self buildSyntaxDictionary];
	// Register for "text changed" notifications of our text storage:
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processEditing:)
									name: NSTextStorageDidProcessEditingNotification
									object: [originalTextView textStorage]];
	
	// set language to what the current front window is not (expecting one to build a vertex then a fragment shader)
	if (!originalString) { // we have a new document
		[self setFileType:@"VertexShaderType"];
		id document = [[NSDocumentController sharedDocumentController] currentDocument]; // this will not work
		if ([document respondsToSelector:@selector(getLanguage)]) 
			if ([document getLanguage] == GL_VERTEX_SHADER_ARB) // if we already have a vertex shader
				[self setFileType:@"FragmentShaderType"];
	}
	typeString = [self fileType];
	if ((NSOrderedSame == [typeString compare:@"VertexShaderType"]) || 
		(NSOrderedSame == [typeString compare:@"VertShaderType"])) {
		language = GL_VERTEX_SHADER_ARB;
		[languagePopUp selectItemAtIndex:0];
	} else if ((NSOrderedSame == [typeString compare:@"FragShaderType"]) || 
			   (NSOrderedSame == [typeString compare:@"FragmentShaderType"])) {
		language = GL_FRAGMENT_SHADER_ARB;
		[languagePopUp selectItemAtIndex:1];
	} else { // unknown, thus must be set
		[self setFileType:@"VertexShaderType"];
		language = GL_VERTEX_SHADER_ARB;
		[languagePopUp selectItemAtIndex:0];
	}

	shader = 0;
	log = NULL;
	logLength = 0;
	status = -1;

    // init fonts for use with strings
    NSFont * font =[NSFont fontWithName:@"Monaco" size:9.0];
    stanStringAttrib = [[NSMutableDictionary dictionary] retain];
    [stanStringAttrib setObject:font forKey:NSFontAttributeName];
    [stanStringAttrib setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    errorStringAttrib = [[NSMutableDictionary dictionary] retain];
    [errorStringAttrib setObject:font forKey:NSFontAttributeName];
    [errorStringAttrib setObject:[NSColor colorWithCalibratedRed:0.6f green:0.0f blue:0.0f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    [font release];

 	if (!originalString) {
		if (language == GL_VERTEX_SHADER_ARB)
			[self setOriginalString :@"uniform vec3 inColor;\nvarying vec3 outColor;\n\nvoid main()\n{\n    outColor = inColor;\n\n    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;\n}\n"];
		else 
			[self setOriginalString :@"varying vec3 outColor;\n\nvoid main()\n{\n    gl_FragColor = vec4(outColor, 1.0);\n}\n"];
	}
	NSAttributedString * string = [[NSAttributedString alloc] initWithString:@"----" attributes:stanStringAttrib];
	[self setLogString:string];
	[string release];
	
	[originalTextView setFont:[NSFont fontWithName: @"Monaco" size:9.0]];
	[self updateOriginalView];
	
	[compileText setStringValue:@"Not compiled."];
	[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:0.745f green:0.745f blue:1.0f alpha:1.0f]];
// leaking a color maybe

	if ([autoCompileCheckBox state]) // if we are auto compiling...
		[self process:self];
	
	[originalTextView setSelectedRange: NSMakeRange(0,0)];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	if (shader)
		[parser releaseShaderHandle: shader];
	if (log)
		free (log);

    [super dealloc];
}


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	[self updateOriginalString];
	return [originalString dataUsingEncoding:NSMacOSRomanStringEncoding allowLossyConversion:YES];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	NSString *aString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	[self setOriginalString:aString];
	[aString release];
	[self updateOriginalView];
    return YES;
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
	NSRange selection = [originalTextView selectedRange];
	int selectionPoint = selection.location + selection.length;
	long  i = 0;
	unsigned start = 0, nextStart = 0, end = 0;
	NSRange range = NSMakeRange (nextStart, 0);
	do { // while end is not in range
		[[self originalString] getLineStart:&start end:&nextStart contentsEnd:&end forRange:range];
		if (range.location == nextStart)
			break;
		range.location = nextStart;
		i++;
	} while (selectionPoint >= nextStart);
	[lineText setIntValue:i];
}

- (void)processEditing:(NSNotification *)notification
{
	NSTextStorage *textStorage = [notification object];
	NSRange found, area;
	NSString *string = [textStorage string];
	unsigned int length = [string length];
	NSArray * keys = [keyWords allKeys];
	NSString * keyWord = nil;
	NSScanner * scanner = [NSScanner scannerWithString: string];
	int last_location = 0;
	NSString * searchString = nil;
	NSEnumerator * wordEnumerator;
	NSRange fooRange;

	area.location = 0;
	area.length = length;
	[textStorage removeAttribute: NSForegroundColorAttributeName range: area];

	// First colorize everything that is not enclosed in quotation marks
	while (![scanner isAtEnd]) {

		// Remember the last location of the scanner (initially zero, then the location of the last quotation mark)
		last_location = [scanner scanLocation];

		// Now scan up to the next (or first) quotation mark into a temporary string
		[scanner scanUpToString: @"\"" intoString: &searchString];

		// Get the length of the temporary string for use below
		length = [searchString length];

		// Advance the scanner one character past the quotation mark we just found
		// UNLESS the scanner is already at the end of the string
		if ([scanner scanLocation] < [string length]) {
			[scanner setScanLocation: [scanner scanLocation] + 1];
		}

		// Initialize the key word enumerator
		wordEnumerator = [keys objectEnumerator];

		// Loop through all of the key words in the array and try to find them within the temporary string
		while (keyWord = [wordEnumerator nextObject]) {

			// Initialize search range
			area.location = 0;
			area.length = length;

			// While there is a area to search...
			while (area.length) {
				bool skip = false;
				// Try to find a key word
				found = [searchString rangeOfString: keyWord options: NSLiteralSearch range: area];

				// If no key word found, try the next key word
				if (found.location == NSNotFound) {
					break;
				}
				// otherwise a key word was found

				// Setup a temporary range to reflect the actual position of the string within the text view
				// by applying the offset of our current scanning location to the location of the key word
				fooRange.location = found.location;
				fooRange.length = found.length;
				fooRange.location += last_location;

				// Work around for an odd bug that only occurs occasionally
				while (![[string substringWithRange: fooRange] isEqual: keyWord]) {
					fooRange.location++;
				}
				// check for word break before and after
 				unichar ch = [[textStorage string] characterAtIndex: fooRange.location + fooRange.length];
				if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || (ch == '_')) {
					skip = true;
				}

				if (found.location >= 1) {
					ch = [[textStorage string] characterAtIndex: fooRange.location - 1];
					if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || (ch == '_')) {
						skip = true;
					}
				}

				if (!skip) // Set the foreground color attribute for the range of text described by the key word
					[textStorage addAttribute: NSForegroundColorAttributeName value: [keyWords objectForKey: keyWord] range: fooRange];

				// Reduce the area to search to exclude the key word we just colorized
				area.location = NSMaxRange(found);
				area.length = length - area.location;
			}
		}
	}

	// Now reset the colorization for anything that was commented out

	// Note: This may seem like a hack, but I found that the performance of the app was
	// worse when trying to embed the logic for exclusion within the key word search.

	// Re-initialize a new scanner to scan the whole string
	scanner = [NSScanner scannerWithString: string];
	while (![scanner isAtEnd]) {

		// Try to find on open comment string
		[scanner scanUpToString: @"/*" intoString: nil];
		last_location = [scanner scanLocation];

		// If we can't find the closing comment string, then set the range to include the whole string
		if (![scanner scanUpToString: @"*/" intoString: nil]) {
			[scanner setScanLocation: [string length]];
		} else {
			// Otherwise we found the closing comment, so compute the range of text to reset
			NSRange resetRange;

			// Advance the scanner past the closing comment string we just found
			if ([scanner scanLocation] < [string length]) {
				[scanner setScanLocation: [scanner scanLocation] + 2];
			}

			// Calculate the range to be reset
			resetRange = NSMakeRange(last_location, [scanner scanLocation] - last_location);

			// Reset the foreground color for the range
			[textStorage addAttribute: NSForegroundColorAttributeName value: colorComments range: resetRange];
		}
	}
	// Now reset the single-line comments
	scanner = [NSScanner scannerWithString: string];
	while (![scanner isAtEnd]) {
		bool foundN = true, foundR = true;
		int locN = 0, locR = 0;
		[scanner scanUpToString: @"//" intoString: nil];
		last_location = [scanner scanLocation];
		if (![scanner scanUpToString: @"\n" intoString: nil]) {
			foundN = false;
			[scanner setScanLocation: [string length]];
		} else {
			locN = [scanner scanLocation];
		}
		[scanner setScanLocation: last_location];
		if (![scanner scanUpToString: @"\r" intoString: nil]) {
			foundR = false;
		
		} else {
			locR = [scanner scanLocation];
		}
		if (!foundN && !foundR) {
			[scanner setScanLocation: [string length]]; // end
		} else {
			NSRange resetRange;
			[scanner setScanLocation: (locR < locN) ? locR : locN];
			if ([scanner scanLocation] < [string length]) {
				[scanner setScanLocation: [scanner scanLocation] + 1];
			}
			resetRange = NSMakeRange(last_location, [scanner scanLocation] - last_location);
			[textStorage addAttribute: NSForegroundColorAttributeName value: colorComments range: resetRange];
		}
	}
}


- (void) textDidChange:(NSNotification *)aNotification
{  
	[self updateChangeCount:NSChangeDone];
	status = -1; // the new text is not compiled
	[compileText setStringValue:@"Not compiled."];
	[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:0.745f green:0.745f blue:1.0f alpha:1.0f]];
	if ([autoCompileCheckBox state]) // if we are auto compiling...
		[self process:self];
}

- (void) logMsg:(NSString*)msg format:(NSMutableDictionary *)attribute
{
	NSAttributedString * string;
	[[logTextView textStorage] beginEditing];
	string = [[NSAttributedString alloc] initWithString:msg attributes:attribute];
	[self appendLogString:string];
	[[logTextView textStorage] endEditing];
	[string release];
}

// returns index of character after token or 0 if token not found.

static long StepToToken (const char * source, char * token)
{
	Boolean fStartToken = false, fEndToken = false;
	char c;
	short posToken = 0, lenToken = (short) strlen (token);
	long index = 0;
	
	do
	{
		c = *(source + index++);
		if (fStartToken) {
			if ((c == *(token + posToken)) ||
				((*(token + posToken) == '\r') && (c == '\n')) ||
				((*(token + posToken) == '\n') && (c == '\r'))) {  // if we are equal to current token char
				posToken++;
				if (posToken == lenToken) // are we done
					fEndToken = true;
			} else { // no match, so copy current matched chars and proceed
				fStartToken = false;
				posToken = 0;
			}
		} else {
			if ((c == *(token + posToken)) ||
				((*(token + posToken) == '\r') && (c == '\n')) ||
				((*(token + posToken) == '\n') && (c == '\r'))) {  // if we are equal to current token char
				posToken++;
				fStartToken = true;
				if (posToken == lenToken) // are we done
					fEndToken = true;
			}
		}
	}
	while ((c != 0) && (!fEndToken));
	if (c == 0)
		return 0;
	return index;
}

- (IBAction) changeAutoCompile: (id) sender
{
	if ([autoCompileCheckBox state]) // if we are auto compiling...
		[self process:self];
}

-(IBAction) changeLinkerEnable: (id) sender
{
	if (shader && [enableInLinkerCheckBox state])
		[parser attachShaderHandle:shader]; // attaches a shader handle to the program
	else if (shader) { 
		[parser detachShaderHandle:shader]; // attaches a shader handle to the program
	}
}

-(GLenum) getLanguage
{
	return language;
}

-(IBAction) changeLanguage: (id) sender
{
	NSString * typeString;
	typeString = [self fileType];
	switch ([languagePopUp indexOfSelectedItem]) {
		case 0:
			if (language != GL_VERTEX_SHADER_ARB) {
				if ((NSOrderedSame == [typeString compare:@"VertexShaderType"]) || 
					(NSOrderedSame == [typeString compare:@"FragmentShaderType"]))
						[self setFileType:@"VertexShaderType"];
				else 
						[self setFileType:@"VertShaderType"];
				language = GL_VERTEX_SHADER_ARB;
				if (shader) { // must recreate shader on language change
					[parser releaseShaderHandle: shader];
				}
				shader = 0;
				status = -1; // the new text is not compiled
				[compileText setStringValue:@"Not compiled."];
				[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:0.745f green:0.745f blue:1.0f alpha:1.0f]];
				if ([autoCompileCheckBox state]) // if we are auto compiling...
					[self process:self];
			}
			break;
		case 1:
			if (language != GL_FRAGMENT_SHADER_ARB) {
				if ((NSOrderedSame == [typeString compare:@"VertexShaderType"]) || 
					(NSOrderedSame == [typeString compare:@"FragmentShaderType"]))
						[self setFileType:@"FragmentShaderType"];
				else 
						[self setFileType:@"FragShaderType"];
				language = GL_FRAGMENT_SHADER_ARB;
				if (shader) { // must recreate shader on language change
					[parser releaseShaderHandle: shader];
				}
				shader = 0;
				status = -1; // the new text is not compiled
				[compileText setStringValue:@"Not compiled."];
				[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:0.8f green:0.8f blue:1.0f alpha:1.0f]];
				if ([autoCompileCheckBox state]) // if we are auto compiling...
					[self process:self];
			}
			break;
	}
}

// called when renderer is changed...
- (void) invalidateShader
{
	shader = 0;
	if ([autoCompileCheckBox state] || status) // if we are auto compiling or if we are already compiled
		[self process:self];
}

- (BOOL) checkReportOpenGLError:(NSString*) function
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err) {
		[self logMsg:[NSString stringWithFormat:@"%@ error: %s.\n", function, (char *) gluErrorString (err)] format:errorStringAttrib];
		return YES;
	} else
		return NO;
}

-(IBAction) process: (id) sender;
{
// maybe leaks strings
 	BOOL error = NO;
		
	[self clearLogString];
	[self updateOriginalString]; // ensure string is up to date
		
	// need to get file name and set language
	if (NO == error) {
		error = [self checkReportOpenGLError: @"On Entry"];
		if (NO == error && 0 == shader && [parser respondsToSelector:@selector(getShaderHandleFor:)]) {
			shader = [parser getShaderHandleFor:language];
			if (shader && [enableInLinkerCheckBox state]) // on shader creation
				[parser attachShaderHandle:shader]; // attaches a shader handle to the program
		}
		if (shader) {
			// set options...
			const char *string = [originalString UTF8String];
			const char* shaderStrings[1] = { string };
			if (NO == error) {
				glShaderSourceARB (shader, 1, shaderStrings, NULL);
				error = [self checkReportOpenGLError: @"glShaderSourceARB"];
			}
			if (NO == error) {
				glCompileShaderARB (shader);
				error = [self checkReportOpenGLError: @"glCompileShaderARB"];
			}
			if (NO == error) {
				glGetObjectParameterivARB (shader, GL_OBJECT_COMPILE_STATUS_ARB, &status);
				error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_COMPILE_STATUS_ARB"];
			}
			if (NO == error) {
				glGetObjectParameterivARB (shader, GL_OBJECT_INFO_LOG_LENGTH_ARB, &logLength);
				error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_INFO_LOG_LENGTH_ARB"];
			}
			if (NULL == log)
				log = (GLcharARB *) malloc (logLength + 1);
			else {
				GLcharARB * newLog = (GLcharARB *) realloc (log, logLength + 1);
				if (newLog)
					log = newLog;
				else {
					free (log);
					log = NULL;
				} 
			}
			if (NO == error && NULL != log) {
				glGetInfoLogARB (shader, logLength, &logLength, log);
				error = [self checkReportOpenGLError: @"glGetInfoLogARB"];
			} else {
				[self logMsg:@"Failed to allocate info log string.\n" format:errorStringAttrib];
				error = YES;
			}
			log[logLength] = 0;
		} else {
			[self logMsg:@"Failed to create shader.\n" format:errorStringAttrib];
			error = YES;
		}
	}
	if (YES == error) { // internal error
		// log already set
		[compileText setStringValue:@"Internal error (see log)."];
	} else { // no GL errors
		const char * errorString;
		long errorLine = 0, lineOffset = 0;
		unsigned start = 0, nextStart = 0, end = 0;

		if (logLength)
			[self logMsg:[NSString stringWithFormat:@"%s", log] format:stanStringAttrib];
		else 
			[self logMsg:@"No log messages" format:stanStringAttrib];

		[[originalTextView textStorage] beginEditing];
		[[originalTextView textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,[[originalTextView textStorage] length])];
		// search for "ERROR: 0:###" then highlight line in red
		errorString = [[self logString]UTF8String];
		lineOffset = StepToToken ((errorString + lineOffset), "ERROR: 0:");
		while (0 != lineOffset) { // if we found a recoginzed line number pattern
			long offset, newLine = atol (errorString + lineOffset);
			if ((newLine != errorLine) && (newLine != -1)) { // if we have a valid error line highlight the line
				long  i;
				NSRange range = NSMakeRange (nextStart, 0);
				for (i = errorLine; i < newLine; i++) {
					[[self originalString] getLineStart:&start end:&nextStart contentsEnd:&end forRange:range];
					range.location = nextStart;
				}
				range = [[self originalString] lineRangeForRange: NSMakeRange(start, 0)];
				
				// red for error line
				[[originalTextView textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedRed:1.0f green:0.75f blue:0.75f alpha:1.0f] range:range];
				errorLine = newLine;
			}
			offset = StepToToken ((errorString + lineOffset), "ERROR: 0:");
			if (!offset)
				break;
			lineOffset += offset;
		}
		// search for "WARNING: 0:###" then highlight line in yellow
		errorString = [[self logString]UTF8String];
		lineOffset = StepToToken ((errorString + lineOffset), "WARNING: 0:");
		while (0 != lineOffset) { // if we found a recoginzed line number pattern
			long offset, newLine = atol (errorString + lineOffset);
			if ((newLine != errorLine) && (newLine != -1)) { // if we have a valid error line highlight the line
				long  i;
				NSRange range = NSMakeRange (nextStart, 0);
				for (i = errorLine; i < newLine; i++) {
					[[self originalString] getLineStart:&start end:&nextStart contentsEnd:&end forRange:range];
					range.location = nextStart;
				}
				range = [[self originalString] lineRangeForRange: NSMakeRange(start, 0)];
				
				// red for error line
				[[originalTextView textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.75f alpha:1.0f] range:range];
				errorLine = newLine;
			}
			offset = StepToToken ((errorString + lineOffset), "WARNING: 0:");
			if (!offset)
				break;
			lineOffset += offset;
		}
		[[originalTextView textStorage] endEditing];
		
		if (1 == status) { // successful compile
			[compileText setStringValue:@"Compile succeeded."];
			[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f]];
			if ([enableInLinkerCheckBox state]) // if we are linking with this shader
				[parser successfulCompile];
		} else { // unsuccessful compile
			[compileText setStringValue:@"Compile failed (see log)."];
			[compileText setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:0.75f blue:0.75f alpha:1.0f]];
		}
	}
}

@end
