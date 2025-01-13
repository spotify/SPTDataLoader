/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
