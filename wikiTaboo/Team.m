//
//  Team.m
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/7/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import "Team.h"

@implementation Team

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.teamName = name;
        self.score = 0;
    }
    return self;
}

@end
