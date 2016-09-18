/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
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
/*
	These are utility routines that are used to parse the command line arguments
	and extract the specified file location, type and format
*/

#include <AudioToolbox/AudioToolbox.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

// external to this file the following function needs to be defined
extern int ConvertFile (FSRef					&inputFSRef, 
					OSType						fileType, 
					FSRef						&dirFSRef, 
					char*						fname, 
					CAStreamBasicDescription	&outputFormat);


bool TestFile (const char* fname, bool inDelete)
{
	// use this to determine if a file exists first
	FILE *f = fopen (fname, "r");
	if (f) {
		fclose (f);
		// wipe out the output file
		if (inDelete) {
			char str[1024];
			sprintf (str, "rm %s", fname);
			system(str);
		}
		return true;
	}
	return false;
}

void UsageString(int exitCode)
{
	printf ("Usage: ConvertFile /path/to/input/file [-d formatID] [-f fileType] [-r sampleRate] [-h]\n");
	printf ("    output file written is /tmp/outfile.<EXT FOR FORMAT>\n");
	printf ("    if -d is specified, out file is written with that format\n");
	printf ("       if no format is specified and input file is 'lpcm', IMA is written\n");
	printf ("       if input file is compressed (ie. not 'lpcm'), then 'lpcm' is written\n");
	printf ("    if -r is specified, input file's format must be ('lpcm') and output is written with new sample rate\n");
	printf ("    if -f is not specified, CAF File is written ('caff')\n");
	exit(exitCode);
}

void str2OSType (const char * inString, OSType &outType)
{
	if (inString == NULL) {
		outType = 0;
		return;
	}
	
	size_t len = strlen(inString);
	if (len <= 4) {
		char workingString[5];
		
		workingString[4] = 0;
		workingString[0] = workingString[1] = workingString[2] = workingString[3] = ' ';
		memcpy (workingString, inString, strlen(inString));
		outType = 	*(workingString + 0) <<	24	|
					*(workingString + 1) <<	16	|
					*(workingString + 2) <<	8	|
					*(workingString + 3);
		return;
	}

	if (len <= 8) {
		if (sscanf (inString, "%lx", &outType) == 0) {
			printf ("* * Bad conversion for OSType\n"); 
			UsageString(1);
		}
		return;
	}
	printf ("* * Bad conversion for OSType\n"); 
	UsageString(1);
}

void ParseArgs (int argc, char * const argv[], 
									OSType	& outFormat, 
									Float64	& outSampleRate,
									OSType	& outFileType,
									FSRef	& outInputFSRef,
									FSRef	& outDirFSRef,
									char	* outFname)
{
	if (argc < 2) UsageString(1);
	
	// first validate our initial condition
	const char* inputFile = argv[1];
	
	if (!TestFile (inputFile, false)) {
		printf ("* * Problem with input file\n"); 
		UsageString(1);
	}

	// look to see if a format or different file output has been specified
	for (int i = 2; i < argc; ++i) {
		if (!strcmp ("-d", argv[i])) {
			str2OSType (argv[++i], outFormat);
			outSampleRate = 0;
		}
		else if (!strcmp ("-r", argv[i])) {
			sscanf (argv[++i], "%lf", &outSampleRate);
			outFormat = 0;
		}
		else if (!strcmp ("-f", argv[i])) {
			str2OSType (argv[++i], outFileType);
		}
		else if (!strcmp ("-h", argv[i])) {
			UsageString(0);
		}
		else {
			printf ("* * Unknown command: %s\n", argv[i]); 
			UsageString(1);
		}
	}
	
	UInt32 size = sizeof(CFArrayRef);
	CFArrayRef extensions;
	OSStatus err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_ExtensionsForType,
				sizeof(OSType), &outFileType,
                &size, &extensions);	
	XThrowIfError (err, "Getting the file extensions for file type");

	// just take the first extension
	CFStringRef ext = (CFStringRef)CFArrayGetValueAtIndex(extensions, 0);
	char extstr[32];
	Boolean res = CFStringGetCString(ext, extstr, 32, kCFStringEncodingUTF8);
	XThrowIfError (!res, "CFStringGetCString");
	
	// release the array as we're done with this now
	CFRelease (extensions);

	sprintf (outFname, "/tmp/outfile.%s", extstr);
	TestFile (outFname, true);	

//  input file.
	CFStringRef filename = CFStringCreateWithCString (NULL, inputFile, kCFStringEncodingUTF8);
	CFURLRef infileurl = CFURLCreateWithFileSystemPath (NULL, filename, kCFURLPOSIXPathStyle, true);
	CFRelease (filename);

	res = CFURLGetFSRef(infileurl, &outInputFSRef);
	CFRelease (infileurl);
	XThrowIfError (!res, "CFURLGetFSRef");

// output file
	CFURLRef dirurl = CFURLCreateWithFileSystemPath (NULL, CFSTR("/tmp"), kCFURLPOSIXPathStyle, true);
	res = CFURLGetFSRef(dirurl, &outDirFSRef);
	CFRelease (dirurl);
	XThrowIfError (!res, "CFURLGetFSRef");

		// now we just need the output file
	sprintf (outFname, "outfile.%s", extstr);
}


void	ConstructOutputFormatFromArgs (FSRef &inputFSRef, OSType format, Float64 sampleRate, CAStreamBasicDescription &outputFormat)
{
	AudioFileID infile;	
	OSStatus err = AudioFileOpen(&inputFSRef, fsRdPerm, 0, &infile);
	XThrowIfError (err, "AudioFileOpen");
	
// get the input file format
	CAStreamBasicDescription inputFormat;
	UInt32 size = sizeof(inputFormat);
	err = AudioFileGetProperty(infile, kAudioFilePropertyDataFormat, &size, &inputFormat);
	XThrowIfError (err, "AudioFileGetProperty kAudioFilePropertyDataFormat");

	if (inputFormat.mFormatID != kAudioFormatLinearPCM && sampleRate > 0) {
		printf ("Can only specify sample rate with linear pcm input file\n");
		UsageString(1);
	}
	
// set up the output file format
	if (!format) {
		if (sampleRate > 0) {
			outputFormat = inputFormat;
			outputFormat.mSampleRate = sampleRate;
		} else {
			if (inputFormat.mFormatID != kAudioFormatLinearPCM)
				format = kAudioFormatLinearPCM;
			else
				format = kAudioFormatAppleIMA4;
		}
	}
		
	if (format) {
		if (format == kAudioFormatLinearPCM) {
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;

			outputFormat.mBytesPerPacket = inputFormat.mChannelsPerFrame * 2;
			outputFormat.mFramesPerPacket = 1;
			outputFormat.mBytesPerFrame = outputFormat.mBytesPerPacket;
			outputFormat.mBitsPerChannel = 16;
			
			outputFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian
									| kLinearPCMFormatFlagIsSignedInteger
									| kLinearPCMFormatFlagIsPacked;
			
		
		} else {
			// need to set at least these fields for kAudioFormatProperty_FormatInfo
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
			
		// use AudioFormat API to fill out the rest.
			size = sizeof(outputFormat);
			err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &outputFormat);
		}
	}
	
	AudioFileClose (infile);
}

int main (int argc, char * const argv[]) 
{
	OSType format = 0;
	Float64 sampleRate = 0;
	OSType fileType = kAudioFileCAFType;
	FSRef inputFSRef;
	FSRef dirFSRef;
	char fname[64];
	
	ParseArgs (argc, argv, format, sampleRate, fileType, inputFSRef, dirFSRef, fname);

//	printf ("args:%4.4s, sample rate:%.1f, fileType: %4.4s\n", (char*)&format, sampleRate, (char*)&fileType);

	CAStreamBasicDescription outputFormat;	
	ConstructOutputFormatFromArgs (inputFSRef, format, sampleRate, outputFormat);
	
//	outputFormat.Print();
	
	return ConvertFile (inputFSRef, fileType, dirFSRef, fname, outputFormat);
}

