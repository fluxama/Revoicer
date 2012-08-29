//
//  RevoicerAppDelegate.h
//  Revoicer
//
//  Created by Shawn Wallace on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "cocos2d.h"
#import "PdAudioController.h"
#import "PdDispatcher.h"

@interface RevoicerAppDelegate : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
	UIWindow *window_;
	UINavigationController *navController_;
	CCDirectorIOS	*director_;							// weak ref
}

@property (nonatomic, retain) PdAudioController *audioController;
@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;
-(void)receiveFloat:(float)value fromSource:(NSString *)source;
-(void) turnOffSound;
-(void) turnOnSound;
//- (void) copyDemoPatchesToUserDomain;

@end