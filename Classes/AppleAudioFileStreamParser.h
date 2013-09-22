//
//  AppleAudioFileStreamParser.h
//  iPhoneStreamingPlayer
//
//  Created by Benny Khoo on 9/16/13.
//
//

#import <Foundation/Foundation.h>

#include <AudioToolbox/AudioToolbox.h>

#include "BKAudioFileStreamParser.h"

@interface AppleAudioFileStreamParser : NSObject<BKAudioFileStreamParser>

- (id) initWithHint:(AudioFileTypeID)fileTypeHint;

@end
