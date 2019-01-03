/*
 Copyright (c) 2015-2019 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
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
