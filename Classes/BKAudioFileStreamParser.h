//
//  BKAudioFileStreamParser.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/16/13.
//
//

#import <Foundation/Foundation.h>

@protocol BKAudioFileStreamDelegate <NSObject>

- (void)handleAudioPackets:(const void *)inInputData
               numberBytes:(UInt32)inNumberBytes
             numberPackets:(UInt32)inNumberPackets
        packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;

- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
                     fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
                                  ioFlags:(UInt32 *)ioFlags;

- (void)failWithErrorCode:(int)anErrorCode;

@end

@protocol BKAudioFileStreamParser <NSObject>

@required
@property (readonly) SInt64 dataOffset;
@property (readonly) UInt64 audioDataByteCount;
@property (readonly) AudioFormatListItem *formatList;

@property (readonly) UInt32 packetSizeUpperBound;
@property (readonly) UInt32 maxPacketSize;

@property (assign) id<BKAudioFileStreamDelegate> delegate;

- (void) getDataFormat:(AudioStreamBasicDescription *) dataFormat;
- (void *) getMagicCookieDataWithLen:(UInt32*)outCookieSize;

- (BOOL) parseData:(const void *)data length:(UInt32)length flags:(UInt32)flags;
- (BOOL) seekOffset:(SInt64)inAbsolutePacketOffset outOffset:(SInt64 *)outAbsoluteByteOffset flags:(UInt32 *)flags;
- (BOOL) open;
- (void) close;

@end


