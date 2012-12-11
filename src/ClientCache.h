/*
 *
 * Copyright (c) 2012 Timo Dörr
 * All rights reserved.
 *
 */
#ifndef SPDY_CLIENT_CACHE_H
#define SPDY_CLIENT_CACHE_H

#include <map>
#include <cstdlib>
#include <vector>
#include <string>

#include <stdint.h>


using namespace std;

namespace spdylay
{

  typedef struct CacheEntry {
    std::string hostport;
    std::string path;

    // send by the server to identify a given content
    uint32_t assoc_content_id;

    // the binary data, currently unused
    void * data;

  } CacheEntry;


  class ClientCache
  {

  public:

    static void Add (CacheEntry entry);
    static bool HasFreshCopy (std::string path);
    static void Clear ();
    static bool enabled;

  private:
    // we currently only store pathes, so do not support multiple hosts/ports
    static map<string, CacheEntry> entries;

  };

}

#endif /* SPDY_CLIENT_CACHE_H */


