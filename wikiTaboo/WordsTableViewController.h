//
//  WordsTableViewController.h
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/6/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Word.h"

@interface WordsTableViewController : UITableViewController

@property (strong, nonatomic) NSString *word;
@property (strong, nonatomic) NSMutableArray *tabooWords;
@property (weak, nonatomic) IBOutlet Word *toBeGuessed;
@property (weak, nonatomic) IBOutlet UINavigationBar *currentTeamLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;


@end
