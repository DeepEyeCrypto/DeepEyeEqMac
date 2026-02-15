//
//  ExceptionCatcher.h
//

#import <Foundation/Foundation.h>
#import <AMCoreAudio/AMCoreAudio.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
  @try {
    tryBlock();
  }
  @catch (NSException *exception) {
    return exception;
  }
  return nil;
}
