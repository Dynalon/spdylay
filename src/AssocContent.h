/*
 *
 * Copyright (c) 2012 Timo Dörr
 * All rights reserved.
 *
 */
#ifndef SPDY_SERVER_ASSOC_H
#define SPDY_SERVER_ASSOC_H

#include <map>
#include <cstdlib>
#include <vector>
#include <string>

#include "SpdyServer.h"
using namespace std;

namespace spdylay
{

	class AssociatedContent
	{

	public:


		static bool verbose;
		static bool HasContent (std::string url);
		static void Fill ();
		static map<string, vector<string> > ContentMap;
		static vector<string> GetAssociatedContent (string url);


	private:
		// associated content always belong to a single request,
		// not necessarily a stream
		spdylay_session *session;


	};


}
#endif // SPDY_SERVER_ASSOC_H
