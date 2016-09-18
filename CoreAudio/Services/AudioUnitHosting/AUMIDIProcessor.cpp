/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
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
/*=============================================================================
	AUMIDIProcessor.cpp
	
=============================================================================*/

/*
	This file is used to process MIDI and push them out to the AU
*/
#include "AudioUnitHosting.h"

void AudioUnitHosting::AUHMIDIReadProc (const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
	AudioUnitHosting* This = (AudioUnitHosting*)readProcRefCon;
	const MIDIPacket *packet = &pktlist->packet[0];
	for (unsigned int i = 0; i < pktlist->numPackets; ++i) {
		This->ParseMIDI (*packet);
		packet = MIDIPacketNext(packet);
	}
}

void AudioUnitHosting::ParseMIDI (const MIDIPacket &packet)
{
	const Byte *p = packet.data, *pend = p + packet.length;
	while (p < pend) {
		Byte c = *p;
		if ((c & 0xE0) == 0xC0) {
			// 2-byte channel messages (program change 0xCn, mono pressure 0xDn)
			MusicDeviceMIDIEvent (mTargetUnit, *p, *(p + 1), 0, 0);
			p += 2;
		} else if ((signed char)c < (signed char)0xF0) {
			// 3 byte channel messages 0x80 - 0xEF (ex. above)
			// 0x8n	- note off, 0x9n - note on, 0xAn - key pressure, 0xBn - control, 0xEn - pitch bend
			MusicDeviceMIDIEvent (mTargetUnit, *p, *(p + 1), *(p + 2), 0);
			p += 3;
		} else {
			// this just skips over any system MIDI messages
			++p;
		}
	}
}
