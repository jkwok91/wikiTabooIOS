//
//  Team.h
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/7/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Team : NSObject

@property (nonatomic,strong) NSString *teamName;
@property (assign) int score;

- (id)initWithName:(NSString *)name;

@end
