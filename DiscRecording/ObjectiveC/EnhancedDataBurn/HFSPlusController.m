/*
     File:       HFSPlusController.m
 
     Contains:   FSPropertyController subclass to handle the HFS+ filesystem.
 
     Version:    Technology: Mac OS X
                 Release:    Mac OS X
 
     Copyright:  (c) 2004 by Apple Computer, Inc., all rights reserved
 
     Bugs?:      For bug reports, consult the following page on
                 the World Wide Web:
 
                     http://developer.apple.com/bugreporter/
*/
/*
 File:  HFSPlusController.m
 
 Copyright:  � Copyright 2004 Apple Computer, Inc. All rights reserved.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under Apple�s
 copyrights in this original Apple software (the "Apple Software"), to use,
 reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions of
 the Apple Software.  Neither the name, trademarks, service marks or logos of
 Apple Computer, Inc. may be used to endorse or promote products derived from the
 Apple Software without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or implied,
 are granted by Apple herein, including but not limited to any patent rights that
 may be infringed by your derivative works or by other works in which the Apple
 Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
 OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
 (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "HFSPlusController.h"

#import <Carbon/Carbon.h>

@implementation HFSPlusController

- (id) init
{
	if (self = [super init])
	{
		// Like in other places, we're doing an object tag -> property mapping to easily
		// convert between the two worlds.
		propertyMappings = [[NSArray alloc] initWithObjects:	DRCreationDate,						//0
																DRContentModificationDate,			//1
																DRAttributeModificationDate,		//2
																DRAccessDate,						//3
																DRBackupDate,						//4
																DRPosixFileMode,					//5
																DRPosixUID,							//6
																DRPosixGID,							//7
																DRMacFileType,						//8
																DRMacFileCreator,					//9
																DRMacWindowBounds,					//10
																DRMacIconLocation,					//11
																DRMacScrollPosition,				//12
																DRMacWindowView,					//13
																DRMacFinderFlags,					//14
																DRMacExtendedFinderFlags,			//15
																DRHFSPlusTextEncodingHint,			//16
																DRHFSPlusCatalogNodeID,				//17
																nil];
	}

	return self;
}

- (NSString*) filesystem
{
	// We're the controller for the HFS+ filesystem, so return the correct value.
	return DRHFSPlus;
}

- (DRFilesystemInclusionMask) mask
{
	// We're the controller for the HFS+ filesystem, so return the correct value.
	return DRFilesystemInclusionMaskHFSPlus;
}

- (void) updateSpecific
{
	[tecHint setObjectValue:[inspectedItem propertyForKey:DRHFSPlusTextEncodingHint inFilesystem:[self filesystem] mergeWithOtherFilesystems:NO]];
	[nodeID setObjectValue:[inspectedItem propertyForKey:DRHFSPlusCatalogNodeID inFilesystem:[self filesystem] mergeWithOtherFilesystems:NO]];

	[super updateSpecific];
}

@end
