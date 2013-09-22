//
//  OggVorbisStreamParser.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/22/13.
//
//

#import <Foundation/Foundation.h>

#import "BKAudioFileStreamParser.h"

@interface OggVorbisStreamParser : NSObject<BKAudioFileStreamParser>

- (id) initWithHint:(AudioFileTypeID)fileTypeHint;

@end
