//
//  OggOpusStreamParser.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/28/13.
//
//

#import <Foundation/Foundation.h>

#import "BKAudioFileStreamParser.h"

@interface OggOpusStreamParser : NSObject<BKAudioFileStreamParser>

- (id) initWithHint:(AudioFileTypeID)fileTypeHint;

@end
