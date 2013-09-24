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

#import <AudioToolbox/AudioToolbox.h>

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
            
            char **ptr=_vorbisComment.user_comments;
            while(*ptr){
                fprintf(stderr,"%s\n",*ptr);
                NSLog(@"%s", *ptr);
                ++ptr;
            }
            
            NSLog(@"Bitstream is %d channel, %ldHz", _vorbisInfo.channels, _vorbisInfo.rate);
            NSLog(@"Encoded by: %s", _vorbisComment.vendor);
            
            // initialize vorbis
            status = vorbis_synthesis_init(&_vorbisDspState, &_vorbisInfo);
            NSAssert(status == 0, @"corrupt header during playback initialization");
            
            vorbis_block_init(&_vorbisDspState, &_vorbisBlock);
            
            _state += readcount;
            
            [self.delegate handlePropertyChangeForFileStream:self fileStreamPropertyID:kAudioFileStreamProperty_DataFormat];
            [self.delegate handlePropertyChangeForFileStream:self fileStreamPropertyID:kAudioFileStreamProperty_ReadyToProducePackets];
        }
        else if (_state == 3) {
            ogg_int16_t convbuffer[4096];
            status = ogg_stream_pagein(&_oggStreamState, &page);
            
            while (1) {
                ogg_packet packet;
                status = ogg_stream_packetout(&_oggStreamState, &packet);
                if (status == 0) {
//                    NSLog(@"bailing out loop");
                    break;
                }
                
                if (status < 0) {
                    NSLog(@"read audio packet error");
                } else {
                    if (vorbis_synthesis(&_vorbisBlock, &packet) == 0) {
                        vorbis_synthesis_blockin(&_vorbisDspState, &_vorbisBlock);
                    }
                    
                    float **pcm;
                    int samples;
                    while((samples=vorbis_synthesis_pcmout(&_vorbisDspState,&pcm))>0){
//                        NSLog(@"found %d PCM samples", samples );
                        
                        int bout=(samples<4096?samples:4096);
                        
                        for(int i=0;i<_vorbisInfo.channels;i++){
                            ogg_int16_t *ptr=convbuffer+i;
                            float  *mono=pcm[i];
                            for(int j=0;j<bout;j++){
#if 1
                                int val=floor(mono[j]*32767.f+.5f);
#else /* optional dither */
                                int val=mono[j]*32767.f+drand48()-0.5f;
#endif
                                /* might as well guard against clipping */
                                if(val>32767){
                                    val=32767;
                                }
                                if(val<-32768){
                                    val=-32768;
                                }
                                *ptr=val;
                                ptr+=_vorbisInfo.channels;
                            }
                        }
                        
                        UInt32 bytesLen = 2 * _vorbisInfo.channels * bout;
                        [self.delegate handleAudioPackets:convbuffer numberBytes:bytesLen numberPackets:0 packetDescriptions:NULL];

                        
                        vorbis_synthesis_read(&_vorbisDspState, bout);
                    }

                }
            }
            
            if (ogg_page_eos(&page)) {
                NSLog(@"received EOS!");
                _state = 0;
            }

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

- (SInt64) dataOffset
{
    return 0;
}

- (UInt64) audioDataByteCount
{
    return 0;
}

- (BOOL) getDataFormat:(AudioStreamBasicDescription *)dataFormat
{
    FillOutASBDForLPCM(*dataFormat,
                       _vorbisInfo.rate, // sample rate (fps)
                       _vorbisInfo.channels, // channels per frame
                       16, // valid bits per channel
                       16, // total bits per channel
                       false, // isFloat
                       false); // isBigEndian
    
    return TRUE;
}

- (AudioFormatListItem *) getFormatListWithLen:(UInt32 *)formatListSize
{
    return NULL;
}

- (UInt32) packetSizeUpperBound
{
    return 2048;
}

- (UInt32) maxPacketSize
{
    return 2048;
}

- (void *) getMagicCookieDataWithLen:(UInt32*)outCookieSize
{
    return NULL;
}



@end
