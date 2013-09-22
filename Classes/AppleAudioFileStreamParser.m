//
//  AppleAudioFileStreamParser.m
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/16/13.
//
//

#import "AppleAudioFileStreamParser.h"
#import "AudioStreamer.h"

@interface AppleAudioFileStreamParser () {
    AudioFileStreamID audioFileStream;
    AudioFileTypeID _fileTypeHint;
}
@end

static void ASPropertyListenerProc(void *						inClientData,
                                   AudioFileStreamID				inAudioFileStream,
                                   AudioFileStreamPropertyID		inPropertyID,
                                   UInt32 *						ioFlags)
{
	// this is called by audio file stream when it finds property values
	AppleAudioFileStreamParser* streamer = (AppleAudioFileStreamParser *)inClientData;
	[streamer.delegate
     handlePropertyChangeForFileStream:inAudioFileStream
     fileStreamPropertyID:inPropertyID
     ioFlags:ioFlags];
}

static void ASPacketsProc(void *							inClientData,
                          UInt32							inNumberBytes,
                          UInt32							inNumberPackets,
                          const void *					inInputData,
                          AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	AppleAudioFileStreamParser* streamer = (AppleAudioFileStreamParser *)inClientData;
	[streamer.delegate
     handleAudioPackets:inInputData
     numberBytes:inNumberBytes
     numberPackets:inNumberPackets
     packetDescriptions:inPacketDescriptions];
}


@implementation AppleAudioFileStreamParser

@synthesize delegate = _delegate;

- (id) initWithHint:(AudioFileTypeID)fileTypeHint
{
    self = [super init];
    if (self) {
        _fileTypeHint = fileTypeHint;
        
    }
    return self;
}

- (BOOL) open
{
    OSStatus err = AudioFileStreamOpen(self, ASPropertyListenerProc, ASPacketsProc,
                                       _fileTypeHint, &audioFileStream);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
        return FALSE;
    }

    return err == 0;
}

- (BOOL) parseData:(const void *)data length:(UInt32)length flags:(UInt32)flags
{
    OSStatus err = AudioFileStreamParseBytes(audioFileStream, length, data, flags);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
        return FALSE;
    }
    return TRUE;
}

- (BOOL) seekOffset:(SInt64)inAbsolutePacketOffset outOffset:(SInt64 *)outAbsoluteByteOffset flags:(UInt32 *)flags
{
    OSStatus err;
    err = AudioFileStreamSeek(audioFileStream, inAbsolutePacketOffset, outAbsoluteByteOffset, flags);
    
    return err == 0;
}

- (void) close
{
    OSStatus err = AudioFileStreamClose(audioFileStream);
    audioFileStream = nil;
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_CLOSE_FAILED];
    }
}

- (SInt64) dataOffset
{
    SInt64 offset;
    UInt32 offsetSize = sizeof(offset);
    OSStatus err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_DataOffset, &offsetSize, &offset);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
        return -1;
    }
    
    return offset;
}

- (UInt64) audioDataByteCount
{
    UInt64 audioDataByteCount;
    UInt32 byteCountSize = sizeof(UInt64);
    OSStatus err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_AudioDataByteCount, &byteCountSize, &audioDataByteCount);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
        return 0;
    }
    
    return audioDataByteCount;
}

- (void) getDataFormat:(AudioStreamBasicDescription *)dataFormat
{
    UInt32 asbdSize = sizeof(*dataFormat);
    
    // get the stream format.
    OSStatus err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, dataFormat);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
        return;
    }
}

- (AudioFormatListItem *) formatList
{
    Boolean outWriteable;
    UInt32 formatListSize;
    OSStatus err;
    
    err = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
    if (err)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
        return NULL;
    }
    
    AudioFormatListItem *formatList = malloc(formatListSize);
    err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
    if (err)
    {
        free(formatList);
        [self.delegate failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
        return NULL;
    }
    
    return formatList;
}

- (UInt32) packetSizeUpperBound
{
    UInt32 packetBufferSize;
    UInt32 sizeOfUInt32 = sizeof(UInt32);
	OSStatus err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &packetBufferSize);
	if (err)
	{
        return 0;
	}
    return packetBufferSize;
}

- (UInt32) maxPacketSize
{
    UInt32 result;
    
    UInt32 sizeOfUInt32 = sizeof(UInt32);
    OSStatus err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &result);
    if (err)
    {
        result = 0;
    }
    return result;
}

- (void *) getMagicCookieDataWithLen:(UInt32*)outCookieSize
{
	// get the cookie size
	UInt32 cookieSize;
	Boolean writable;
	OSStatus ignorableError;
	ignorableError = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
	if (ignorableError)
	{
		return NULL;
	}
    *outCookieSize = cookieSize;
    
	// get the cookie data
	void* cookieData = calloc(1, cookieSize);
	ignorableError = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
	if (ignorableError)
	{
		return NULL;
	}
    
    return cookieData;
}

@end
