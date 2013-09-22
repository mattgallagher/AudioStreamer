//
//  OggVorbisStreamParser.m
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/22/13.
//
//

#import "OggVorbisStreamParser.h"
#import "AudioStreamer.h"

#import "Ogg/ogg.h"
#import "Vorbis/codec.h"

@interface OggVorbisStreamParser () {
    ogg_sync_state _oggSyncState;
    ogg_stream_state _oggStreamState;
    
    vorbis_info _vorbisInfo;
    vorbis_comment _vorbisComment;
    vorbis_dsp_state _vorbisDspState;
    vorbis_block _vorbisBlock;
    
    int _state;
    
}

@end

@implementation OggVorbisStreamParser

@synthesize delegate = _delegate;

- (id) initWithHint:(AudioFileTypeID)fileTypeHint
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL) open
{
    ogg_sync_init(&_oggSyncState);
    
    vorbis_info_init(&_vorbisInfo);
    vorbis_comment_init(&_vorbisComment);
    
    _state = 0;

    return TRUE;
}

- (BOOL) parseData:(const void *)data length:(UInt32)length flags:(UInt32)flags
{
    char *buffer;
    buffer = ogg_sync_buffer(&_oggSyncState, 4096);
    memcpy(buffer, data, length);
    
    int status = ogg_sync_wrote(&_oggSyncState, length);
    if (status != 0)
    {
        [self.delegate failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
        return FALSE;
    }
    
    ogg_page page;
    int result = ogg_sync_pageout(&_oggSyncState, &page);
    if (result == 0) {
//        NSLog(@"more data needed");
        return TRUE;
    }
    else if (result < 0) {
        NSLog(@"Corrupt or missing data in bitstream; continuing...");
    }
    else {
        // call handles
//        NSLog(@"should handle audio packets");
        
        if (_state == 0) {
            int serialno = ogg_page_serialno(&page);
            ogg_stream_init(&_oggStreamState, serialno);
            
            status = ogg_stream_pagein(&_oggStreamState, &page);
            if (status < 0) {
                NSLog(@"Error reading first page of Ogg bitstream data.");
                return FALSE;
            }
            
            ogg_packet packet;
            status = ogg_stream_packetout(&_oggStreamState, &packet);
            if (status != 1) {
                NSLog(@"Error reading initial header packet");
                return FALSE;
            }
            
            status = vorbis_synthesis_headerin(&_vorbisInfo, &_vorbisComment, &packet);
            if (status < 0) {
                NSLog(@"This Ogg bitstream does not contain Vorbis");
                return FALSE;
            }
            
            _state++;

        }
        else if (_state > 0 && _state < 3) {
            status = ogg_stream_pagein(&_oggStreamState, &page);
            
            int readcount = 0;
            while (readcount < 2) {
                ogg_packet packet;
                status = ogg_stream_packetout(&_oggStreamState, &packet);
                if (status == 0)
                    break;
                
                if (status != 1) {
                    NSLog(@"Corrupt secondary header.");
                    return FALSE;
                }
                
                status = vorbis_synthesis_headerin(&_vorbisInfo, &_vorbisComment, &packet);
                if (status < 0) {
                    NSLog(@"Corrupt secondary Vorbis header.");
                    return FALSE;
                }
                
                readcount++;
            }
            
            _state += readcount;
        }
        else if (_state == 3) {
            char **ptr=_vorbisComment.user_comments;
            while(*ptr){
                fprintf(stderr,"%s\n",*ptr);
                NSLog(@"%s", *ptr);
                ++ptr;
            }

            NSLog(@"Bitstream is %d channel, %ldHz", _vorbisInfo.channels, _vorbisInfo.rate);
            NSLog(@"Encoded by: %s", _vorbisComment.vendor);
            _state++;
        }
    }
    
    return TRUE;
}

- (BOOL) seekOffset:(SInt64)inAbsolutePacketOffset outOffset:(SInt64 *)outAbsoluteByteOffset flags:(UInt32 *)flags
{
//    OSStatus err;
//    err = AudioFileStreamSeek(audioFileStream, inAbsolutePacketOffset, outAbsoluteByteOffset, flags);
//    
//    return err == 0;
    return FALSE;
}

- (void) close
{
    ogg_sync_clear(&_oggSyncState);
}



@end
