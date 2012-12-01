/*
 *
 * Copyright (c) 2012 Timo Dörr
 * All rights reserved.
 *
 */
#include "AssocContent.h"

#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>

#include <sstream>
#include <fstream>

#include <spdylay/spdylay.h>
#include <iostream>

#include <map>
#include <vector>


using namespace spdylay;
using namespace std;

namespace spdylay
{

	bool AssociatedContent::HasContent (std::string url)
	{
	  if(!AssociatedContent::enabled)
	    return false;

		bool has_content = ContentMap.find (url) != ContentMap.end ();
		if (verbose && has_content) {
			cout << "found associated content for " << url << endl;
		}
		if (verbose && !has_content) {
			cout << "no associated content found for " << url << endl;
		}
		return has_content;
	};
	vector<string> AssociatedContent::GetAssociatedContent (std::string url)
	{
		return ContentMap[url];

	}
	// build the static associated content table
	void AssociatedContent::Fill ()
	{
    if(!AssociatedContent::enabled)
      return;

    DIR * dirp = opendir(config.htdocs.c_str ());
    dirent *dp;

    while ((dp = readdir(dirp)) != NULL) {
      // skip ./.. dirs
      if (strcmp(dp->d_name, "..") == 0 || strcmp(dp->d_name, ".") == 0) continue;

      // concatenate to full path
      size_t new_size = config.htdocs.length() + strlen(dp->d_name) + 1;
      char *fullpath = (char*) malloc(new_size);
      sprintf(fullpath, "%s%s", config.htdocs.c_str (), dp->d_name);

      // check if it is directory
      struct stat buff;
      lstat(fullpath, &buff);
      if (S_ISDIR(buff.st_mode)) {
        // read in all associated content for that dir
        addHtdocsDir (std::string(fullpath), std::string(dp->d_name));
      }
    }
    closedir(dirp);
	}

	// adds a directory within htdocs
	// each directory must have a assoc.txt describing the associated content
	// for index.html
	void AssociatedContent::addHtdocsDir (string fullpath, string basepath)
	{
	  // find all .map files
    DIR * dirp = opendir(fullpath.c_str());
    dirent *dp;
    while ((dp = readdir(dirp)) != NULL) {
      // skip ./.. dirs
      if (strcmp(dp->d_name, "..") == 0 || strcmp(dp->d_name, ".") == 0)
        continue;

      std::string s(dp->d_name);
      if (s.length() < 4) continue;
      string end = s.substr(s.length() - 4,4);

      if (end == ".map") {
        string htmlfile = s.substr(0, s.length () - 4);
        string htmlpath = "/" + basepath + "/" + htmlfile;

        string mappath = fullpath + "/" + s;

        vector<string> index_vec =  vector<string> ();
        std::ifstream input(mappath.c_str());

        // push each content as associated content into our map
        for(std::string line; getline(input, line); ) {
          // combine to full path
          string assoc_content_path = basepath + "/" + line;
          index_vec.push_back(assoc_content_path);
          //cout << assoc_content_path << endl;
        }
        input.close();

        cout << htmlpath << endl;
        ContentMap.insert(pair<string, vector<string> > (htmlpath, index_vec));
      }
    }
    closedir (dirp);
	}
	// static initializations
	map<string, vector<string> > AssociatedContent::ContentMap = map<string, vector<string> > ();
	bool AssociatedContent::verbose = false;
	bool AssociatedContent::enabled = false;
	Config AssociatedContent::config;

}

