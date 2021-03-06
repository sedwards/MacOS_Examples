/*
	File:		LayoutPane.cp

	Contains:	Class to drive our layout pane, demonstrating group boxes.

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

	Copyright � 1997-2001 Apple Computer, Inc., All Rights Reserved
*/

#include "AppearanceSamplePrefix.h"

#if !BUILDING_FOR_CARBON_8
	#include <Carbon/Carbon.h>
#else
	#include <Carbon.h>
#endif

#include "LayoutPane.h"
#include "AppearanceHelpers.h"
#include "UDialogUtils.h"

enum
{
	kPrimaryGroup		= 1,
	kUserPane			= 2,
	kSecondaryGroup		= 3,
	kSeparator			= 4,
	kRadioGroup			= 5,
	kLevel1Radio		= 6,
	kLevel2Radio		= 7,
	kLevel3Radio		= 8,
	kUseMilliCheck		= 9,
	kFullCheck			= 10
};

LayoutPane::LayoutPane( DialogPtr dialog, SInt16 items ) : MegaPane( dialog, items )
{
	ControlHandle	control;
	
	AppendDialogItemList( dialog, 6500, overlayDITL );
	
	UDialogUtils::SetItemValue( dialog, fOrigItems + kPrimaryGroup, 1 );
	
	GetDialogItemAsControl( dialog, fOrigItems + kLevel1Radio, &control );
	SetControlMaximum( control, 2 );
	GetDialogItemAsControl( dialog, fOrigItems + kLevel2Radio, &control );
	SetControlMaximum( control, 2 );
	GetDialogItemAsControl( dialog, fOrigItems + kLevel3Radio, &control );
	SetControlMaximum( control, 2 );
	UDialogUtils::SetItemValue( dialog, fOrigItems + kRadioGroup, 2 );
	UDialogUtils::SetItemValue( dialog, fOrigItems + kLevel3Radio, 1 );
	UDialogUtils::SetItemValue( dialog, fOrigItems + kLevel1Radio, 2 );
	UDialogUtils::SetItemValue( dialog, fOrigItems + kLevel1Radio, 0 );
	UDialogUtils::SetItemValue( dialog, fOrigItems + kLevel2Radio, 1 );
}

LayoutPane::~LayoutPane()
{
	ShortenDITL( fDialog, CountDITL( fDialog ) - fOrigItems );
}

void
LayoutPane::ItemHit( SInt16 item )
{
	SInt16			localItem;
	ControlHandle	control;
	
	localItem = item - fOrigItems;
	
	switch( localItem )
	{
		case kPrimaryGroup:
			UDialogUtils::ToggleCheckBox( fDialog, item );
			GetDialogItemAsControl( fDialog, fOrigItems + kUserPane, &control );
			if ( UDialogUtils::GetItemValue( fDialog, item ) == 1 )
				EnableControl( control );
			else
				DisableControl( control );
			break;
		
		case kUseMilliCheck:
		case kFullCheck:
			UDialogUtils::ToggleCheckBox( fDialog, item );
			break;
			
	}
}
