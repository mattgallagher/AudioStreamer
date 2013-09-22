//
//  BKAudioFileStreamParser.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/16/13.
//
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

@protocol BKAudioFileStreamParser;
@protocol BKAudioFileStreamDelegate <NSObject>

- (void)handleAudioPackets:(const void *)inInputData
               numberBytes:(UInt32)inNumberBytes
             numberPackets:(UInt32)inNumberPackets
        packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;

- (void)handlePropertyChangeForFileStream:(id<BKAudioFileStreamParser>)audioFileStreamParser
                     fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID;

- (void)failWithErrorCode:(int)anErrorCode;

@end

@protocol BKAudioFileStreamParser <NSObject>

@required
@property (readonly) SInt64 dataOffset;
@property (readonly) UInt64 audioDataByteCount;

@property (readonly) UInt32 packetSizeUpperBound;
@property (readonly) UInt32 maxPacketSize;

@property (assign) id<BKAudioFileStreamDelegate> delegate;

- (BOOL) getDataFormat:(AudioStreamBasicDescription *) dataFormat;
- (void *) getMagicCookieDataWithLen:(UInt32*)outCookieSize;
- (AudioFormatListItem *) getFormatListWithLen:(UInt32 *)formatListSize;

- (BOOL) parseData:(const void *)data length:(UInt32)length flags:(UInt32)flags;
- (BOOL) seekOffset:(SInt64)inAbsolutePacketOffset outOffset:(SInt64 *)outAbsoluteByteOffset flags:(UInt32 *)flags;
- (BOOL) open;
- (void) close;

@end


