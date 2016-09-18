/*
	File:		IconSheet.cp

	Contains:	Sheet to create a icon control.

    Version:	Mac OS X

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
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

	Copyright � 2000-2001 Apple Computer, Inc., All Rights Reserved
*/

#include "IconSheet.h"
#include "AppearanceHelpers.h"
#if !BUILDING_FOR_CARBON_8
	#include <Carbon/Carbon.h>
#else
	#include <Carbon.h>
#endif

const ControlID 	kIconPopup 		= { 'ICON', 1 };
const ControlID 	kSizePopup 		= { 'ICON', 2 };
const ControlID 	kNoHitCheck 		= { 'ICON', 3 };

enum { k16Pixels = 1, k32Pixels, k48Pixels, k128Pixels };

IconSheet::IconSheet( TWindow* parent )
		: CDEFTesterSheet( CFSTR( "Icon" ), parent )
{
	Show();
}

IconSheet::~IconSheet()
{
}

ControlRef
IconSheet::CreateControl()
{
	ControlRef				control = NULL;
	ControlRef				tempControl;
	Rect					bounds = { 0, 0, 0, 0 };
	SInt32					height, width;
	IconRef					icon;
	OSStatus				err;
	Boolean					dontTrack;
	OSType					iconType[] = { 0, kGenericFolderIcon, kGenericApplicationIcon,
											kGenericHardDiskIcon, kFinderIcon };
	ControlButtonContentInfo info;
	
	::GetControlByID( GetWindowRef(), &kIconPopup, &tempControl );
	err = GetIconRef( 0, kSystemIconsCreator,
					iconType[ ::GetControlValue( tempControl ) ], &icon );

		
	::GetControlByID( GetWindowRef(), &kSizePopup, &tempControl );
	switch ( ::GetControlValue( tempControl ) )
	{
		default:
		case k16Pixels:
			height = width = 16;
			break;
		case k32Pixels:
			height = width = 32;
			break;
		case k48Pixels:
			height = width = 48;
			break;
		case k128Pixels:
			height = width = 128;
			break;
	}
	
	bounds.bottom = height;
	bounds.right = width;
	
	::GetControlByID( GetWindowRef(), &kNoHitCheck, &tempControl );
	dontTrack = ( ::GetControlValue( tempControl ) == 1 );
	
	info.contentType = kControlContentIconRef;
	info.u.iconRef = icon;
	
	::CreateIconControl( GetParentWindowRef(), &bounds, &info, dontTrack, &control );
	
	::ReleaseIconRef( icon );
	
	if ( control )
		SetControlVisibility( control, false, false );

	return control;
}