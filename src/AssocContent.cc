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

      // concatenate to full path (+2 because of the trailing / and 0 termination)
      size_t new_size = config.htdocs.length() + strlen(dp->d_name) + 1;
      char *fullpath = (char*) malloc(new_size);
      sprintf(fullpath, "%s%s", config.htdocs.c_str (), dp->d_name);

      // check if it is directory
      struct stat buff;
      lstat(fullpath, &buff);
      if (S_ISDIR(buff.st_mode)) {
        // read in all associated content for that dir
        addHtdocsDir (fullpath, dp->d_name);
      }
    }
    closedir(dirp);
	}

	// adds a directory within htdocs
	// each directory must have a assoc.txt describing the associated content
	// for index.html
	void AssociatedContent::addHtdocsDir (char* fullpath, char* basepath)
	{
	  // append assoc.txt
	  char * assoc_file = (char *) malloc (strlen(fullpath) + 11);
	  sprintf(assoc_file, "%s/assoc.txt", fullpath);

	  char *index_relpath = (char *) malloc (strlen(basepath) + 13);
	  sprintf(index_relpath, "/%s/index.html", basepath);

	  vector<string> index_vec =  vector<string> ();
	  std::ifstream input(assoc_file);

	  for(std::string line; getline(input, line); ) {

	    char * assoc_content = (char *) malloc (line.length() + strlen(basepath) + 2);
	    sprintf(assoc_content, "%s/%s", basepath, line.c_str());
	    index_vec.push_back (assoc_content);
	    cout << assoc_content << endl;
	  }
		ContentMap.insert(pair<string, vector<string> > (index_relpath, index_vec));
	}
	// static initializations
	map<string, vector<string> > AssociatedContent::ContentMap = map<string, vector<string> > ();
	bool AssociatedContent::verbose = false;
	bool AssociatedContent::enabled = false;
	Config AssociatedContent::config;

}

