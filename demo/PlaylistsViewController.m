/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "PlaylistsViewController.h"

#import "PlaylistsViewModel.h"

@interface PlaylistsViewController () <PlaylistsViewModelDelegate>

@property (nonatomic, strong) PlaylistsViewModel *model;

@end

@implementation PlaylistsViewController

#pragma mark PlaylistsViewController

- (instancetype)initWithModel:(PlaylistsViewModel *)model
{
    if (!(self = [super init])) {
        return nil;
    }

    self.title = NSLocalizedString(@"Playlists", @"");
    _model = model;
    _model.delegate = self;

    return self;
}

#pragma mark PlaylistsViewModelDelegate

- (void)playlistsViewModelDidLoad:(PlaylistsViewModel *)model
{
    [self.tableView reloadData];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(self.class)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.model load];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)self.model.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    cell.textLabel.text = self.model.items[(NSUInteger)indexPath.row][@"name"];

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: do something here
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
