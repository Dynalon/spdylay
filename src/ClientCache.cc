/*
 *
 * Copyright (c) 2012 Timo Dörr
 * All rights reserved.
 *
 */
#include "ClientCache.h"

#include <iostream>

#include <map>
#include <vector>
#include <fstream>


using namespace spdylay;
using namespace std;

namespace spdylay
{


  void ClientCache::Add(CacheEntry entry) {
    if (!enabled) return;
    cout << "Adding cache entry " << entry.path << endl;
    pair<string, CacheEntry> p = pair<string, CacheEntry> (entry.path, entry);
    entries.insert(p);

  }
   bool ClientCache::HasFreshCopy(std::string path) {
     if (!enabled) return false;

    cout << "Client cache looking up " << path << " ";
    CacheEntry ce = CacheEntry ();
    ce.path = path;
    map<string, CacheEntry>::iterator it;
    it = entries.find(ce.path);
    if (it != entries.end()) {
      cout << "HIT" <<endl;
      return true;
    }
    cout << "MISS" << endl;
    return false;
  }
 void ClientCache::Clear () {
   if (!enabled) return;
    entries.clear();
  }


  map<string, CacheEntry> ClientCache::entries;
  bool ClientCache::enabled = false;
}
