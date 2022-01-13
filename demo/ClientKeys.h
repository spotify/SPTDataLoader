/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#pragma once

/*
 Create a new Spotify application on the Spotify developer portal and copy the client ID
 and client secret into this file. Add the redirect URI below to your new applicaton under
 the "Redirect URIs" section.

 https://developer.spotify.com/my-applications/#!/applications/create
 */

#define SPOTIFY_CLIENT_ID      @"INSERT_YOUR_CLIENT_ID"
#define SPOTIFY_CLIENT_SECRET  @"INSERT_YOUR_CLIENT_SECRET"
#define SPOTIFY_REDIRECT_URI   @"sptdataloaderdemo://login"
