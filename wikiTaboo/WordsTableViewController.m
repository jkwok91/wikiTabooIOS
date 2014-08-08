//
//  WordsTableViewController.m
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/6/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import "WordsTableViewController.h"

@interface WordsTableViewController ()

@end

@implementation WordsTableViewController {
    NSArray *doesntCount;
    NSTimer *roundTimer;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // create recentLogs array
        self.tabooWords = [[NSMutableArray alloc] init];
        doesntCount = @[@"^",@"help page",@"references or sources",@"improve this article",@"adding citations to reliable sources"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // grab the main word from the wiki api
    [self getNewRound];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)getNewRound {
    [self getNewWord];
    // i also need to create and update the timer label so people know how much time is left
    [self showWord];
    [self performSelector:@selector(getNewRound) withObject:self afterDelay:1.0f];
}

- (void)getNewWord {
    NSDictionary* json;
    
    NSURL *randomWord = [NSURL URLWithString:@"http://en.wikipedia.org/w/api.php?action=query&format=json&list=random&rnnamespace=0&rnlimit=1"];
    
    // parse out the json data
    json = [self getJSON:randomWord];
    self.word = [[[[json objectForKey:@"query"] objectForKey:@"random"] objectAtIndex:0] objectForKey:@"title"];
    
    // now get the taboo words
    NSString *wordFormattedForURL = [self.word stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *urlString = [NSString stringWithFormat:@"http://en.wikipedia.org/w/api.php?format=json&action=parse&prop=text&page=%@&redirects=true&section=0",wordFormattedForURL];
    NSURL *randomPage = [NSURL URLWithString:urlString];
    
    json = [self getJSON:randomPage];
    // entire page in one string
    NSMutableString *text = [[[json objectForKey:@"parse"] objectForKey:@"text"] objectForKey:@"*"];
    NSError *error;
    // get all the linked words
    // regex for linked words
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^>]+( [A-Za-z0-9\u00A0-\uFFFF]+)*)(?=</a>)" options:0 error:&error];
    
    /* thanks, SO:
       http://stackoverflow.com/questions/16204218/nsstring-regex-string-matching-search
     */
    [regex enumerateMatchesInString:text options:0 range:NSMakeRange(0, [text length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        
        // detect
        NSString *insideString = [text substringWithRange:[match rangeAtIndex:1]];
        for (NSString *str in doesntCount) {
            if (![insideString isEqualToString:str] && ![self.tabooWords containsObject:insideString]) {
                // load into taboo words array
                [self.tabooWords addObject:insideString];
            }
        }
    }];
    [self.tableView reloadData];
    
    NSRegularExpression *tagRegex = [NSRegularExpression regularExpressionWithPattern:@"<[^<>]+>" options:0 error:&error];
    text = [tagRegex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:@""];
    NSLog(text);
}

- (NSDictionary *)getJSON:(NSURL *)requestURL {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
    
    NSData *urlData;
    NSURLResponse *response;
    NSError *error;
    
    // Make synchronous request
    urlData = [NSURLConnection sendSynchronousRequest:request
                                    returningResponse:&response
                                                error:&error];
    
    //NSLog([[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding]);
    // parse out the json data
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:urlData
                          options:kNilOptions
                          error:&error];
    return json;
}

- (void)showWord {
    self.toBeGuessed.text = self.word;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.tabooWords count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSUInteger row = [indexPath row];
    NSUInteger count = [self.tabooWords count]; // here listData is your data source
    cell.textLabel.text = [self.tabooWords objectAtIndex:(count-row-1)];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
