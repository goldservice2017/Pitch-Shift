//
//  ViewController.m
//  PitchShift
//
//  Created by mac on 1/18/16.
//  Copyright © 2016 mac. All rights reserved.
//

#import "ViewController.h"
#import "TheAmazingAudioEngine.h"
#import <AEAudioController.h>
#import <AEPlaythroughChannel.h>
#import <AEExpanderFilter.h>
#import <AELimiterFilter.h>
#import <AERecorder.h>
#import <AEReverbFilter.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
{
    AEAudioController* audioController;
    AudioFileID _audioUnitFile;
    NSString* filePath;
    
    BOOL isPlaying;
    float currentPitchValue;
}
@property (nonatomic, weak) IBOutlet UIButton* btnPlayer;
@property (nonatomic, weak) IBOutlet UIImageView* imgPlayer;
@property (nonatomic, weak) IBOutlet UISlider* pichSlider;
@property (nonatomic, weak) IBOutlet UILabel* lblPitchValue;
@property (nonatomic, strong) AEAudioFilePlayer* player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    filePath = [[NSBundle mainBundle] pathForResource:@"heart" ofType:@"wav"];
    isPlaying = NO;
    audioController = [[AEAudioController alloc] initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleavedFloatStereo inputEnabled:YES];
    audioController.preferredBufferDuration = 0.005;
    audioController.useMeasurementMode = YES;
    [audioController start:NULL];
    [self.lblPitchValue setText:@"0 cents"];
}
- (IBAction)actionPlayer:(id)sender{
    if (isPlaying) {
        [audioController removeChannels:@[self.player]];
        self.player = nil;
        [self.imgPlayer setImage:[UIImage imageNamed:@"play.png"]];
        isPlaying = NO;
    }else{
        NSURL* fileUrl = [NSURL fileURLWithPath:filePath];
        NSError* error = nil;
        self.player = [[AEAudioFilePlayer alloc] initWithURL:fileUrl error:&error];
        if (!self.player) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"alert" message:@"Couldn't open playback" preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        self.player.removeUponFinish = YES;
//        self.player = nil;
//        [self.imgPlayer setImage:[UIImage imageNamed:@"pause.png"]];
        
        __weak ViewController* weakSelf = self;
        self.player.completionBlock = ^{
            ViewController* strongSelf = weakSelf;
            [strongSelf.imgPlayer setImage:[UIImage imageNamed:@"pause.png"]];
            weakSelf.player = nil;
        };
        [audioController addChannels:@[self.player]];
        isPlaying = YES;
    }
}
- (IBAction)actionPitchSlide:(id)sender{
    UISlider* slider = (UISlider*)sender;
    float pitchValue = slider.value;
    if (pitchValue >= self.pichSlider.maximumValue) {
        pitchValue = self.pichSlider.maximumValue;
    }
    if (pitchValue <= self.pichSlider.minimumValue) {
        pitchValue = self.pichSlider.minimumValue;
    }
    currentPitchValue = pitchValue;
    [self.lblPitchValue setText:[NSString stringWithFormat:@"%.1f cents",pitchValue]];
    
    [self ChangePitch:pitchValue];
}
- (void)ChangePitch:(float)pitch{
   
    AEAudioUnitFilter* pitchFilter = [[AEAudioUnitFilter alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_NewTimePitch) preInitializeBlock:nil];
    [pitchFilter setupWithAudioController:audioController];
    OSStatus status = AudioUnitSetParameter(pitchFilter.audioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0);
    if (status == noErr) {
        NSArray* array = audioController.channels;
        id channel = audioController.channels[0];
        [audioController addFilter:pitchFilter];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
