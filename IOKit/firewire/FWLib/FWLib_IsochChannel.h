/*
	File:		FWLib_IsochChannel.h

	Synopsis: 	C++ Interface for IOFireWireLibIsochChannel

	Copyright: 	© Copyright 2001-2003 Apple Computer, Inc. All rights reserved.

	Written by: NWG
	
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple‚Äôs
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

	$Log: FWLib_IsochChannel.h,v $
	Revision 1.2  2005/02/02 23:20:17  firewire
	*** empty log message ***
	
	Revision 1.1  2004/02/06 23:29:12  firewire
	*** empty log message ***
	

*/
/*
 *  FWLib_IsochChannel.h
 *  FWLib
 *
 *  Created by Niels on Thu Nov 06 2003.
 *  Copyright (c) 2003 Apple Computer, Inc. All rights reserved.
 *
 */

#import <IOKit/firewire/IOFireWireLib.h>
#import <IOKit/firewire/IOFireWireLibIsoch.h>
#import <FWLib/FWLib_IsochPort.h>

namespace FWLib {

	class Device ;
	class NuDCLPool ;
	
	class IsochChannel
	{	
		public :
		
			typedef void (*ForceStopHandler)( IsochChannel * channel, UInt32 reason ) ;
	
		private:
		
			IOFireWireLibIsochChannelRef	mChannel ;
			ForceStopHandler				mForceStopHandler ;
	
		public:
		
			IsochChannel( Device& device, bool doIRM, unsigned packetSize,
					IOFWSpeed preferredSpeed ) ;
			virtual ~IsochChannel() ;
			
		public :
		
			IOReturn			AllocateChannel()								{ return (**mChannel).AllocateChannel( mChannel ) ; }
			IOReturn			ReleaseChannel()								{ return (**mChannel).ReleaseChannel( mChannel ) ; }
			IOReturn			SetTalker( IsochPort * talker )					{ return (**mChannel).SetTalker( mChannel, talker ? talker->Interface() : nil ) ; }
			IOReturn			Start()											{ return (**mChannel).Start( mChannel ) ; }
			IOReturn			Stop()											{ return (**mChannel).Stop( mChannel ) ; }

			void				SetForceStopHandler( ForceStopHandler handler ) ;
			bool				TurnOnNotification()							{ return (bool)(**mChannel).TurnOnNotification( mChannel ) ; }
			void				TurnOffNotification()							{ (**mChannel).TurnOffNotification( mChannel ) ; }

		private :
		
			static void			S_ForceStopHandler( IOFireWireLibIsochChannelRef channel, UInt32 reason ) ;
	} ;

} // namespace FWLib
