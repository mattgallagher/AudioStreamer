//
//  OggOpusStreamParser.m
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/28/13.
//
//

#import "OggOpusStreamParser.h"
#import "AudioStreamer.h"

#import "Ogg/ogg.h"
#import "Opus/opus.h"
#import "Opus/opusfile.h"

@interface OggOpusStreamParser () {
    ogg_sync_state _oggSyncState;
    ogg_stream_state _oggStreamState;
    
    OpusHead _header;
    OpusMSDecoder *_opusDecoder;
    
    int _state;

}
@end

@implementation OggOpusStreamParser

@synthesize delegate = _delegate;

- (id) initWithHint:(AudioFileTypeID)fileTypeHint
{
    self = [super init];
    if (self) {
        _opusDecoder = NULL;
    }
    return self;
}

- (BOOL) open
{
    ogg_sync_init(&_oggSyncState);
    
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
            
            
            status = opus_head_parse(&_header, packet.packet, packet.bytes);
            if (status < 0) {
                NSLog(@"OggOpus parse header error: %d", status);
                return FALSE;
            }
            
            if (_opusDecoder != NULL) {
                opus_multistream_decoder_destroy(_opusDecoder);
            }
            
            int err;
            _opusDecoder = opus_multistream_decoder_create(48000, _header.channel_count, _header.stream_count,
                                                           _header.coupled_count, _header.mapping, &err);
            
            // FIXME set opus gain ... see opusfile.c:op_make_decode_ready
            
            _state++;
            
        }
        else if (_state > 0 && _state < 2) {
            
            status = ogg_stream_pagein(&_oggStreamState, &page);
            if (status < 0) {
                NSLog(@"Error reading first page of Ogg bitstream data.");
                return FALSE;
            }
            
            ogg_packet packet;
            status = ogg_stream_packetout(&_oggStreamState, &packet);
            switch (status) {
                case 0:
                    // insufficient data
                    break;
                
                case -1:
                    // bad header
                    NSLog(@"bad Opus header");
                    return FALSE;
                    
                default:
                    // got a valid packet
                    OpusTags tags;
                    int ret = opus_tags_parse(&tags, packet.packet, packet.bytes);
                    if (ret < 0) {
                        NSLog(@"parse Opus tags error: %d", ret);
                        return FALSE;
                    }
                    
                    ret = ogg_stream_packetout(&_oggStreamState, &packet);
                    
                    // The final packet SHOULD complete on the last page, i.e., the final lacing value should be less than 255
                    // http://wiki.xiph.org/OggOpus
                    if (ret != 0 || page.header[page.header_len - 1] == 255) {
                        // if fail we assume the tags are uninitialized - follow opusfile.c implementation
                        opus_tags_clear(&tags);
                        return FALSE;
                    }
                    
                    // valid tags here
                    NSLog(@"vendor: %s", tags.vendor);
                    for (int i = 0; i < tags.comments; i++) {
                        // assuming is a null terminated string
                        NSLog(@"%d: %s", i, tags.user_comments[i]);
                    }
                    
                    _state++;
                    
                    break;
            }
            
            if (status > 0) {
                [self.delegate handlePropertyChangeForFileStream:self fileStreamPropertyID:kAudioFileStreamProperty_DataFormat];
                [self.delegate handlePropertyChangeForFileStream:self fileStreamPropertyID:kAudioFileStreamProperty_ReadyToProducePackets];
            }

            
        }
        else if (_state == 2) {
            
            // frame_size int: The number of samples per channel of available space in pcm.
            // If this is less than the maximum packet duration (120 ms; 5760 for 48kHz), this function will not be capable of decoding some packets.
            opus_int16  pcm[120*48*2];
            
            status = ogg_stream_pagein(&_oggStreamState, &page);
            
            BOOL loop = TRUE;
            while (loop) {
                ogg_packet packet;
                status = ogg_stream_packetout(&_oggStreamState, &packet);
                switch (status) {
                    case 0:
                        loop = FALSE;
//                        NSLog(@"exiting loop");
                        break;
                        
                    case -1:
                        // try again
                        break;
                        
                    default:
                        int nframes = opus_packet_get_nb_frames(packet.packet, packet.bytes);
                        if (nframes < 0) {
                            NSLog(@"audio packet error: opus_packet_get_nb_frames error: %d", nframes);
                            loop = FALSE;
                            break;
                        }
                        
                        int frame_size = opus_packet_get_samples_per_frame(packet.packet, 48000);
                        int nsamples = nframes * frame_size;
                        
                        // OggOpus IETF: The duration of an Opus packet may be any multiple of 2.5 ms, up to a maximum of 120 ms
                        // which comes up to 120*48 max samples
                        if (nsamples > 120*48) {
                            NSLog(@"audio packet error: nsamples > 120*48");
                            loop = FALSE;
                            break;
                        }
                        
                        int ret = opus_multistream_decode(_opusDecoder, packet.packet, packet.bytes, pcm, nsamples, 0);
                        NSAssert(ret < 0 || ret == nsamples, @"decode error");
//                        NSLog(@"decoded %d samples", ret);
                        
                        UInt32 bytesLen = 2 * _header.channel_count * nsamples;
                        [self.delegate handleAudioPackets:pcm numberBytes:bytesLen numberPackets:0 packetDescriptions:NULL];

                        break;
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
    _state = 0;
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
                       48000, // sample rate (fps)
                       _header.channel_count, // channels per frame
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
    return 120*48*2;
}

- (UInt32) maxPacketSize
{
    return 120*48*2;
}

- (void *) getMagicCookieDataWithLen:(UInt32*)outCookieSize
{
    return NULL;
}



@end
