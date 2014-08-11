//
//  WordsTableViewController.h
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/6/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Word.h"

@interface WordsTableViewController : UITableViewController <UIGestureRecognizerDelegate>
@property (strong, nonatomic) NSMutableDictionary *cards;
@property (strong, nonatomic) NSMutableArray *listOfWords;
@property (strong, nonatomic) NSString *word;
@property (strong, nonatomic) NSMutableArray *tabooWords;
@property (weak, nonatomic) IBOutlet UILabel *toBeGuessed;
@property (weak, nonatomic) IBOutlet UILabel *currentTeamLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (weak, nonatomic) IBOutlet UIButton *guessedWord;

- (IBAction)buttonTapped:(UIButton *)sender;
- (IBAction)pause:(UIButton *)sender;

@end
