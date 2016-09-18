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
#import "GLSLController.h"
#import "MyDocument.h"

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>

@implementation GLSLParser

- (GLhandleARB)getShaderHandleFor:(GLenum)shaderType // get shader handle from parser (this will be attached to program object)
{
	[controller setCurrent];
	GLhandleARB shader = glCreateShaderObjectARB (shaderType);
	return shader;
}

- (void)attachShaderHandle:(GLhandleARB)handle // attaches a shader handle to the program
{
	[controller setCurrent];
	if (0 == program)  // create a program if needed
		program = glCreateProgramObjectARB ();
	glAttachObjectARB (program, handle); // attach created shader to program
	[controller autoLink:self];		// force update as needed
}

- (void)detachShaderHandle:(GLhandleARB)handle // detaches a shader handle to the program
{
	[controller setCurrent];
	if (0 == program) // create a program if needed
		program = glCreateProgramObjectARB ();
	glDetachObjectARB (program, handle); // attach created shader to program
	[controller autoLink:self];	// force update as needed
}

- (void)releaseShaderHandle:(GLhandleARB)shaderHandle // this will allow the parser to destory the handle
{
	GLint attachedObjects = 0;
	[controller setCurrent];
	// could be detached already...
	glGetObjectParameterivARB (program, GL_OBJECT_ATTACHED_OBJECTS_ARB, &attachedObjects); // get number of attached objects
	if (0 < attachedObjects ) { // if we have attached objects
		GLhandleARB * objects = NULL;
		int i;
		objects = (GLhandleARB *) malloc (attachedObjects * sizeof (GLhandleARB *)); // allocate list of handles
		glGetAttachedObjectsARB (program, attachedObjects, &attachedObjects, objects); // get list of attached objects
		for (i = 0; i < attachedObjects; i++) { // for all attached objects
			if (shaderHandle == objects[i]) { // if we find our object in the list
				glDetachObjectARB(program, shaderHandle); // should not be required to detach first but do it anyway for completeness
				break; // can only be attached once
			}
		}
		free (objects);
	}
	glDeleteObjectARB(shaderHandle);
	// link is now invalid (sort of)
	// relink if auto link
	[controller autoLink:self];	
}

- (void)successfulCompile // a shader was compiled successfully
{
	[controller autoLink:self];
}

- (BOOL) checkReportOpenGLError:(NSString*) function
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err) {
		[controller appendLogString:[NSString stringWithFormat:@"%@ error: %s.\n", function, (char *) gluErrorString (err)]];
		return YES;
	} else
		return NO;
}

- (void)setLinkResults // a shader was compiled successfully
{
	GLint maxLength;
	GLint i, j, uniformCount, attribCount;
	GLcharARB **name;
	GLsizei *length;
	GLint *size;
	GLenum *type, error;
	NSString * string, *finalString;

	// attributes
	
	glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB, &maxLength);
	glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_ATTRIBUTES_ARB, &attribCount);

	size   = (GLint *) malloc(attribCount * sizeof(GLint));
	type   = (GLenum *) malloc(attribCount * sizeof(GLenum));
	length = (GLsizei *) malloc(attribCount * sizeof(GLsizei));
	name   = (GLcharARB **) malloc(attribCount * sizeof(GLcharARB **));

	for (i = 0; i < attribCount; i++) {
		name[i] = (GLcharARB *) malloc(maxLength * sizeof(GLcharARB));
		glGetActiveAttribARB(program, i, maxLength, &length[i], &size[i], &type[i], name[i]);
	}

	// GetActiveUniform test
	finalString = [NSString stringWithFormat:@"\nglGetActiveAttribARB Test: Active Attributes (%ld with max len of %ld):\n  < Index: Name (Type) >\n", attribCount, maxLength];
	for (i = 0; i < attribCount; i++) {
		string = [NSString stringWithFormat:@"%ld: %s ", i, name[i]];
		finalString = [finalString stringByAppendingString:string];
		switch (type[i]) { // get type in text form
			case GL_FLOAT:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT)"]; break;
			case GL_FLOAT_VEC2_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC2_ARB)"]; break;
			case GL_FLOAT_VEC3_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC3_ARB)"]; break;
			case GL_FLOAT_VEC4_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC4_ARB)"]; break;
			case GL_INT:   finalString = [finalString stringByAppendingString:@"(GL_INT)"]; break;
			case GL_INT_VEC2_ARB:   finalString = [finalString stringByAppendingString:@"(GL_INT_VEC2_ARB)"]; break;
			case GL_INT_VEC3_ARB:   finalString = [finalString stringByAppendingString:@"(GL_INT_VEC3_ARB)"]; break;
			case GL_INT_VEC4_ARB:   finalString = [finalString stringByAppendingString:@"(GL_INT_VEC4_ARB)"]; break;
			case GL_BOOL_ARB:   finalString = [finalString stringByAppendingString:@"(GL_BOOL_ARB)"]; break;
			case GL_BOOL_VEC2_ARB:   finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC2_ARB)"]; break;
			case GL_BOOL_VEC3_ARB:   finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC3_ARB)"]; break;
			case GL_BOOL_VEC4_ARB:   finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC4_ARB)"]; break;
			case GL_FLOAT_MAT2_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT2_ARB)"]; break;
			case GL_FLOAT_MAT3_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT3_ARB)"]; break;
			case GL_FLOAT_MAT4_ARB:   finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT4_ARB)"]; break;
			default:  finalString = [finalString stringByAppendingString:@"(No type info)"]; break;
		}
		if (size[i] > 1)
			string = [NSString stringWithFormat:@" <array detected (%ld)- error>\n", size[i]];
		else if (size[i] == 0)
			string = [NSString stringWithFormat:@" <No size info>\n"];
		else
			string = [NSString stringWithFormat:@"\n"];
		finalString = [finalString stringByAppendingString:string];
	}

	string = [NSString stringWithFormat:@"\nglGetAttribLocationARB Test:\n  < Name @ Location >\n"];
	finalString = [finalString stringByAppendingString:string];
	for (i = 0; i < attribCount; i++) {
		int location;
		location = glGetAttribLocationARB (program, name[i]);
		string = [NSString stringWithFormat:@"%s @ %d\n", name[i], location]; // print base output
		finalString = [finalString stringByAppendingString:string];
	}

	for (i = 0; i < attribCount; i++)
		free (name[i]);
	free (size);
	free (type);
	free (length);
	free (name);

	string = [NSString stringWithFormat:@"\n----\n\n"];
	finalString = [finalString stringByAppendingString:string];
	// uniforms
	
	NSPopUpButton * upd = [controller getUniformPullDown];
	[upd removeAllItems];
	
	glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB, &maxLength);
	glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_UNIFORMS_ARB, &uniformCount);

	size   = (GLint *) malloc(uniformCount * sizeof(GLint));
	type   = (GLenum *) malloc(uniformCount * sizeof(GLenum));
	length = (GLsizei *) malloc(uniformCount * sizeof(GLsizei));
	name   = (GLcharARB **) malloc(uniformCount * sizeof(GLcharARB **));

	
	for (i = 0; i < uniformCount; i++) {
		name[i] = (GLcharARB *) malloc(maxLength * sizeof(GLcharARB));
		glGetActiveUniformARB(program, i, maxLength, &length[i], &size[i], &type[i], name[i]);
		if (-1 != glGetUniformLocationARB (program, name[i])) { // find user uniform
			[upd addItemWithTitle:[NSString stringWithFormat:@"%s", name[i]]];
			[controller addUniformWithTitle:[NSString stringWithFormat:@"%s", name[i]]];
			if (size[i] > 1) { // do we have an array?
				GLcharARB* elementName = (GLcharARB *) malloc(strlen(name[i]) + 17 + 1);
				GLcharARB* baseName    = strdup(name[i]);
				GLcharARB* firstBrace  = strchr(baseName, '[');
				if (firstBrace) {
					firstBrace[0] = 0;
					int onItem;
					for (onItem = 1; onItem < size[i]; onItem++) {
						sprintf(elementName, "%s[%d]", baseName, onItem);
						[upd addItemWithTitle:[NSString stringWithFormat:@"%s", elementName]];
						[controller addUniformWithTitle:[NSString stringWithFormat:@"%s", elementName]];
					}
				}
				free(baseName);
				free(elementName);
			}
		}
	}
	[controller setNumUniforms:[upd numberOfItems]];
	if ([upd numberOfItems] == 0) {
		[upd addItemWithTitle:@"No Uniforms"];
		[upd setEnabled:false];
		[controller disableUniforms];
	} else {
		[upd setEnabled:true];
	}
	
	// GetActiveUniform test
	
	string = [NSString stringWithFormat:@"glGetActiveUniformARB Test: Active Uniforms (%ld with max len of %ld):\n  < Index: Name (Type) [Size] >\n", uniformCount, maxLength];
	finalString = [finalString stringByAppendingString:string];
	for (i = 0; i < uniformCount; i++) {
		string = [NSString stringWithFormat:@"%ld: %s ", i, name[i]];
		finalString = [finalString stringByAppendingString:string];
		switch (type[i]) { // get type in text form
			case GL_FLOAT: finalString = [finalString stringByAppendingString:@"(GL_FLOAT)"]; break;
			case GL_FLOAT_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC2_ARB)"]; break;
			case GL_FLOAT_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC3_ARB)"]; break;
			case GL_FLOAT_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_VEC4_ARB)"]; break;
			case GL_INT:  finalString = [finalString stringByAppendingString:@"(GL_INT)"]; break;
			case GL_INT_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"(GL_INT_VEC2_ARB)"]; break;
			case GL_INT_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"(GL_INT_VEC3_ARB)"]; break;
			case GL_INT_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"(GL_INT_VEC4_ARB)"]; break;
			case GL_BOOL_ARB:  finalString = [finalString stringByAppendingString:@"(GL_BOOL_ARB)"]; break;
			case GL_BOOL_VEC2_ARB:  finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC2_ARB)"]; break;
			case GL_BOOL_VEC3_ARB:  finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC3_ARB)"]; break;
			case GL_BOOL_VEC4_ARB:  finalString = [finalString stringByAppendingString:@"(GL_BOOL_VEC4_ARB)"]; break;
			case GL_FLOAT_MAT2_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT2_ARB)"]; break;
			case GL_FLOAT_MAT3_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT3_ARB)"]; break;
			case GL_FLOAT_MAT4_ARB:  finalString = [finalString stringByAppendingString:@"(GL_FLOAT_MAT4_ARB)"]; break;
			case GL_SAMPLER_1D_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_1D_ARB)"]; break;
			case GL_SAMPLER_2D_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_2D_ARB)"]; break;
			case GL_SAMPLER_3D_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_3D_ARB)"]; break;
			case GL_SAMPLER_CUBE_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_CUBE_ARB)"]; break;
			case GL_SAMPLER_1D_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_1D_SHADOW_ARB)"]; break;
			case GL_SAMPLER_2D_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_2D_SHADOW_ARB)"]; break;
			case GL_SAMPLER_2D_RECT_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_2D_RECT_ARB)"]; break;
			case GL_SAMPLER_2D_RECT_SHADOW_ARB:  finalString = [finalString stringByAppendingString:@"(GL_SAMPLER_2D_RECT_SHADOW_ARB)"]; break;
			default: finalString = [finalString stringByAppendingString:@"(No type info)"]; break;
		}
		if (size[i] > 1)
			string = [NSString stringWithFormat:@" [%ld]\n", size[i]];
		else if (size[i] == 0)
			string = [NSString stringWithFormat:@" [No size info]\n"];
		else
			string = [NSString stringWithFormat:@"\n"];
		finalString = [finalString stringByAppendingString:string];
	}

	// GetUniformLocation test
	string = [NSString stringWithFormat:@"\nglGetUniformLocationARB Test:\n  < Name @ Location >\n"];
	finalString = [finalString stringByAppendingString:string];
	for (i = 0; i < uniformCount; i++) {
		int location;
		if (size[i] > 1) {
			int length;
			GLcharARB * tempName   = (GLcharARB *) malloc(strlen(name[i]) + 10); // malloc a big enough buffer
			length = strlen(name[i]) - 3;
			strncpy (tempName, name[i] , length); // copy all but array index
			tempName[length] = 0; // terminate
			location = glGetUniformLocationARB (program, tempName); // base member without array index
			string = [NSString stringWithFormat:@"%s @ %d\n", tempName, location]; // print base output
			finalString = [finalString stringByAppendingString:string];
			for (j = 0; j < size[i]; j++) {
				char index [10];
				sprintf (index, "[%ld]", j); // form index
				strcat (tempName, index); // add index
				location = glGetUniformLocationARB (program, tempName);
				string = [NSString stringWithFormat:@" %s @ %d\n", tempName, location]; // print index output
				finalString = [finalString stringByAppendingString:string];
				tempName[length] = 0; // terminate back at start point
			}
			free (tempName);
		} else {
			location = glGetUniformLocationARB (program, name[i]);
			string = [NSString stringWithFormat:@"%s @ %d\n", name[i], location]; // print base output
			finalString = [finalString stringByAppendingString:string];
		}
	}
	[controller setResultsString :finalString];
	for (i = 0; i < uniformCount; i++)
		free (name[i]);
	free (size);
	free (type);
	free (length);
	free (name);
	error = glGetError(); // clear GL error
}

- (void) setCurrentUniform:(int)index // sets current uniform select by menu
{
	if (program && status) { // if we have valid linked program
		GLint maxLength = 0;
		GLint uniformCount = 0;
		
		glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB, &maxLength);
		glGetObjectParameterivARB(program, GL_OBJECT_ACTIVE_UNIFORMS_ARB, &uniformCount);

		currName = (GLcharARB *) malloc(maxLength * sizeof(GLcharARB));

		currentUniformIndex = index;
		GLint onIndex = 0;
		GLint i;
		int found = 0;
		for (i = 0; !found && i < uniformCount; i++) {
			glGetActiveUniformARB(program, i, maxLength, &currLength, &currSize, &currType, currName);
			currLocation = glGetUniformLocationARB (program, currName);
			if (-1 != currLocation) { // find user uniform
				if (onIndex == currentUniformIndex) {
					[controller setUniformInfo:currName withLocation:currLocation withLength:currLength withType:currType withSize:currSize];
					found = 1;
				}
				onIndex++;
				if (currSize > 1) { // do we have an array?
					GLcharARB* elementName = (GLcharARB *) malloc(strlen(currName) + 17 + 1);
					GLcharARB* baseName    = strdup(currName);
					GLcharARB* firstBrace  = strchr(baseName, '[');
					if (firstBrace) {
						firstBrace[0] = 0;
						int onItem;
						for (onItem = 1; !found && onItem < currSize; onItem++) {
							if (onIndex == currentUniformIndex) {
								sprintf(elementName, "%s[%d]", baseName, onItem);
								[controller setUniformInfo:elementName withLocation:currLocation withLength:currLength withType:currType withSize:currSize];
								found = 1;
							}
							onIndex++;
						}
					}
					free(baseName);
					free(elementName);
				}
			}
		}
		free (currName);
	}
}

- (void) setUniformInt:(uniformValue *)value // value for current uniform
{
	if (program && [controller usingShaderPraogram]) {
		BOOL error = NO;
		GLfloat fGetVal[16];
		GLint iGetVal[16];
		
		switch (currType) {
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
				glUniform1iARB (currLocation, (int)[value getCurrentValAtIndex:0]);
				break;
			case GL_INT_VEC2_ARB:
			case GL_BOOL_VEC2_ARB:
				glUniform2iARB (currLocation, (int)[value getCurrentValAtIndex:0], (int)[value getCurrentValAtIndex:1]);
				break;
			case GL_INT_VEC3_ARB:
			case GL_BOOL_VEC3_ARB:
				glUniform3iARB (currLocation, (int)[value getCurrentValAtIndex:0], (int)[value getCurrentValAtIndex:1], (int)[value getCurrentValAtIndex:2]);
				break;
			case GL_INT_VEC4_ARB:
			case GL_BOOL_VEC4_ARB:
				glUniform4iARB (currLocation, (int)[value getCurrentValAtIndex:0], (int)[value getCurrentValAtIndex:1], (int)[value getCurrentValAtIndex:2], (int)[value getCurrentValAtIndex:3]);
				break;
			default: 
				break;
		}
		glValidateProgramARB (program);
		error = [self checkReportOpenGLError: @"glValidateProgramARB"];
		if (NO == error) {
			glGetObjectParameterivARB (program, GL_OBJECT_VALIDATE_STATUS_ARB, &valid);
			error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_VALIDATE_STATUS_ARB"];
		}
		if (valid) {
			[controller setLinkText:@"Link and Validate succeeded.\n"];
			[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f]];
		} else {
			[controller setLinkText:@"Link succeeded, Validate failed (see log).\n"];
			[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.6f alpha:1.0f]];
		}

		glGetUniformfvARB (program, currLocation, fGetVal);
		glGetUniformivARB (program, currLocation, iGetVal);
		[controller setUniformFloatData:fGetVal];	 
		[controller setUniformIntData:iGetVal];
	}
}

- (void) setUniformFloat:(uniformValue *)value // value for current uniform
{
	if (program && [controller usingShaderPraogram]) {
		BOOL error = NO;
		int i;
		GLfloat fGetVal[16];
		GLint iGetVal[16];
		
		switch (currType) {
			case GL_FLOAT: 
				glUniform1fARB (currLocation, [value getCurrentValAtIndex:0]);
				break;
			case GL_FLOAT_VEC2_ARB:  
				glUniform2fARB (currLocation, [value getCurrentValAtIndex:0], [value getCurrentValAtIndex:1]);
				break;
			case GL_FLOAT_VEC3_ARB:  
				glUniform3fARB (currLocation, [value getCurrentValAtIndex:0], [value getCurrentValAtIndex:1], [value getCurrentValAtIndex:2]);
				break;
			case GL_FLOAT_VEC4_ARB:  
				glUniform4fARB (currLocation, [value getCurrentValAtIndex:0], [value getCurrentValAtIndex:1], [value getCurrentValAtIndex:2], [value getCurrentValAtIndex:3]);
				break;
			case GL_FLOAT_MAT2_ARB:
				for (i = 0; i < 4; i++)
					fGetVal[i] = [value getCurrentValAtIndex:i];
				glUniformMatrix2fvARB (currLocation, 1, GL_FALSE, fGetVal);
			case GL_FLOAT_MAT3_ARB:
				for (i = 0; i < 9; i++)
					fGetVal[i] = [value getCurrentValAtIndex:i];
				glUniformMatrix3fvARB (currLocation, 1, GL_FALSE, fGetVal);
			case GL_FLOAT_MAT4_ARB:
				for (i = 0; i < 16; i++)
					fGetVal[i] = [value getCurrentValAtIndex:i];
				glUniformMatrix4fvARB (currLocation, 1, GL_FALSE, fGetVal);
			default: 
				break;
		}
		glValidateProgramARB (program);
		error = [self checkReportOpenGLError: @"glValidateProgramARB"];
		if (NO == error) {
			glGetObjectParameterivARB (program, GL_OBJECT_VALIDATE_STATUS_ARB, &valid);
			error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_VALIDATE_STATUS_ARB"];
		}
		if (valid) {
			[controller setLinkText:@"Link and Validate succeeded.\n"];
			[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f]];
		} else {
			[controller setLinkText:@"Link succeeded, Validate failed (see log).\n"];
			[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.6f alpha:1.0f]];
		}

		glGetUniformfvARB (program, currLocation, fGetVal);
		glGetUniformivARB (program, currLocation, iGetVal);
		[controller setUniformFloatData:fGetVal];	 
		[controller setUniformIntData:iGetVal];
	}
}


- (GLhandleARB)getLinkedProgram
{
	if (status) // even if it is invalid we should draw with it
		return program;
	else 
		return NULL;
}

- (void)link
{
 	BOOL error = NO;
	status = 0;
	valid = 0;

	[controller setCurrent]; // ensures our context is current
	[controller clearLogString];
	error = [self checkReportOpenGLError: @"-(void)link"];

	if (0 == program && NO == error) {
		program = glCreateProgramObjectARB ();
		error = [self checkReportOpenGLError: @"glCreateProgramObjectARB"];
	}
	if (program && NO == error) {
		glLinkProgramARB (program);
		error = [self checkReportOpenGLError: @"glLinkProgramARB"];
	} else {
		[controller appendLogString:@"Failed to create program.\n"];
		error = YES;
	}
	if (NO == error) {
		glGetObjectParameterivARB (program, GL_OBJECT_LINK_STATUS_ARB, &status);
		error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_LINK_STATUS_ARB"];
	}
	if (NO == error) {
		glValidateProgramARB (program);
		error = [self checkReportOpenGLError: @"glValidateProgramARB"];
	}
	if (NO == error) {
		glGetObjectParameterivARB (program, GL_OBJECT_VALIDATE_STATUS_ARB, &valid);
		error = [self checkReportOpenGLError: @"glGetObjectParameterivARB GL_OBJECT_VALIDATE_STATUS_ARB"];
	}
	if (NO == error) {
		glGetObjectParameterivARB (program, GL_OBJECT_INFO_LOG_LENGTH_ARB, &logLength);
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
		glGetInfoLogARB (program, logLength, &logLength, log);
		error = [self checkReportOpenGLError: @"glGetInfoLogARB"];
	} else {
		[controller appendLogString:@"Failed to allocate info log string.\n"];
		error = YES;
	}
	log[logLength] = 0;
	if (YES == error) { // internal error
		// log already set
		[controller setLinkText:@"Internal error (see log)."];
		[controller setResultsString :@"Link Failed (internal error)"];
		[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:0.5f blue:0.5f alpha:1.0f]];
		NSPopUpButton * upd = [controller getUniformPullDown];
		[upd removeAllItems];
		[controller setNumUniforms:[upd numberOfItems]];
		[upd addItemWithTitle:@"No Uniforms"];
		[upd setEnabled:false];
		[controller disableUniforms];
	} else { // no GL errors
		if (logLength)
			[controller appendLogString:[NSString stringWithFormat:@"%s", log]];
		else 
			[controller appendLogString:@"No log messages"];
		if (1 == status) { // successful link
			if (1 == valid) {
				[controller setLinkText:@"Link and Validate succeeded.\n"];
				[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:0.75f green:1.0f blue:0.75f alpha:1.0f]];
			} else {
				[controller setLinkText:@"Link succeeded, Validate failed (see log).\n"];
				[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.6f alpha:1.0f]];
			}
			
			[self setLinkResults];
			[controller setUnformControls]; // after link set current control settings
		} else { // unsuccessful link
			[controller setLinkText:@"Link failed (see log)."];
			[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:1.0f green:0.75f blue:0.75f alpha:1.0f]];
			[controller setResultsString :@"Link Failed."];
			NSPopUpButton * upd = [controller getUniformPullDown];
			[upd removeAllItems];
			[controller setNumUniforms:[upd numberOfItems]];
			[upd addItemWithTitle:@"No Uniforms"];
			[upd setEnabled:false];
			[controller disableUniforms];
		}
	}
	[controller updateResultsView];
	[controller shaderRedraw]; // ensure drawing is updated if needed
}

- (void) awakeFromNib
{
	[ MyDocument setParser:self];
	[[controller linkResultTextField] setBackgroundColor:[NSColor colorWithCalibratedRed:0.745f green:0.745f blue:1.0f alpha:1.0f]];
}

- (void) dealloc
{
	if (program)
		glDeleteObjectARB(program);
	if (log)
		free (log);

    [super dealloc];
}

- (void) invalidateProgram // called on renderer change to 
{
	program = 0;
}

@end
