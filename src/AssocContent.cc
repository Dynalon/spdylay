/*
 *
 * Copyright (c) 2012 Timo Dörr
 * All rights reserved.
 *
 */
#include "AssocContent.h"

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
	void AssociatedContent::Fill ()
	{
		// add our sample associated contents

		// index.html
		vector<string> index_vec =  vector<string> ();
		index_vec.push_back ("styles.css");
		index_vec.push_back ("script.js");

		ContentMap.insert(pair<string, vector<string> > ("/index.html", index_vec));
	}
	// static initializations
	map<string, vector<string> > AssociatedContent::ContentMap = map<string, vector<string> > ();
	bool AssociatedContent::verbose = false;

}

