/*
 * Spdylay - SPDY Library
 *
 * Copyright (c) 2012 Tatsuhiro Tsujikawa
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#include "HtmlParser.h"

#include "util.h"
#include "uri.h"

#include <iostream>
#include "dirent.h"
#include <sys/stat.h>
#include <fstream>
#include <vector>
#include <map>

namespace spdylay {

ParserData::ParserData(const std::string& base_uri)
  : base_uri(base_uri)
{}

HtmlParser::HtmlParser(const std::string& base_uri, bool use_assoc_file, std::string htdocspath)
  : base_uri_(base_uri),
    parser_ctx_(0),
    parser_data_(base_uri)
{
  this->use_assoc_file = use_assoc_file;

  // build the static list of associated content we need to fetch manually
  if (use_assoc_file) {

    // for every folder in htdocs
    DIR * dirp = opendir(htdocspath.c_str());
    dirent *dp;

    while ((dp = readdir(dirp)) != NULL) {
      // skip ./.. dirs
      std::string filename(dp->d_name);
      if (filename == ".." || filename == ".")
        continue;


      std::string filepath = htdocspath + "/" + filename;
      struct stat buff;
      lstat(filepath.c_str(), &buff);
      if (S_ISDIR(buff.st_mode)) {
        // read in all associated content for that dir
        addHtdocsDir (htdocspath, filename);
      }
    }
    closedir(dirp);
  }
}

void HtmlParser::addHtdocsDir (std::string htdocspath, std::string dirname)
{
  std::string dirpath (htdocspath + "/" + dirname);
  DIR * dirp = opendir(dirpath.c_str());
  dirent *dp;

  while ((dp = readdir(dirp)) != NULL) {
    // skip ./.. dirs
    std::string filename(dp->d_name);

    if (filename.length() < 4) continue;
    std::string end = filename.substr(filename.length() - 4,4);


    if (end == ".map") {
      std::string htmlfile = filename.substr(0, filename.length () - 4);
      std::string htmlpath = "/" + dirname + "/" + htmlfile;
      std::string mappath = htdocspath + dirname + "/" + filename;

      std::ifstream input(mappath.c_str());

      // push each content as associated content into our map
      std::vector<std::string> index_vec = std::vector<std::string> ();
      for (std::string line; getline(input, line);) {
        // combine to full path
        uri::UriStruct us;
        uri::parse(us, this->base_uri_);
        std::string assoc_content_url = "https://" + us.host + ":8080" + "/" + dirname + "/" + line;
        index_vec.push_back(assoc_content_url);
        //std::cout << assoc_content_url << std::endl;
      }
      input.close();
      this->pushed_links_.insert(std::pair<std::string, std::vector<std::string> >(htmlpath, index_vec));
    }
  }
  closedir(dirp);

}

HtmlParser::~HtmlParser()
{
  htmlFreeParserCtxt(parser_ctx_);
}

namespace {
const char* get_attr(const xmlChar **attrs, const char *name)
{
  for(; *attrs; attrs += 2) {
    if(util::strieq(reinterpret_cast<const char*>(attrs[0]), name)) {
      return reinterpret_cast<const char*>(attrs[1]);
    }
  }
  return 0;
}
} // namespace

namespace {
void start_element_func
(void* user_data,
 const xmlChar *name,
 const xmlChar **attrs)
{
  ParserData *parser_data = reinterpret_cast<ParserData*>(user_data);
  if(util::strieq(reinterpret_cast<const char*>(name), "link")) {
    const char *rel_attr = get_attr(attrs, "rel");
    const char *href_attr = get_attr(attrs, "href");
    if((util::strieq(rel_attr, "shortcut icon") ||
        util::strieq(rel_attr, "stylesheet")) &&
       href_attr) {
      std::string uri = uri::joinUri(parser_data->base_uri, href_attr);
      parser_data->links.push_back(uri);
    }
  } else if(util::strieq(reinterpret_cast<const char*>(name), "img")) {
    const char *src_attr = get_attr(attrs, "src");
    if(src_attr) {
      std::string uri = uri::joinUri(parser_data->base_uri, src_attr);
      parser_data->links.push_back(uri);
    }
  } else if(util::strieq(reinterpret_cast<const char*>(name), "script")) {
    const char *src_attr = get_attr(attrs, "src");
    if(src_attr) {
      std::string uri = uri::joinUri(parser_data->base_uri, src_attr);
      parser_data->links.push_back(uri);
    }
  }
}
} // namespace

namespace {
xmlSAXHandler saxHandler =
  {
    0, // internalSubsetSAXFunc
    0, // isStandaloneSAXFunc
    0, // hasInternalSubsetSAXFunc
    0, // hasExternalSubsetSAXFunc
    0, // resolveEntitySAXFunc
    0, // getEntitySAXFunc
    0, // entityDeclSAXFunc
    0, // notationDeclSAXFunc
    0, // attributeDeclSAXFunc
    0, // elementDeclSAXFunc
    0, //   unparsedEntityDeclSAXFunc
    0, //   setDocumentLocatorSAXFunc
    0, //   startDocumentSAXFunc
    0, //   endDocumentSAXFunc
    &start_element_func, //   startElementSAXFunc
    0, //   endElementSAXFunc
    0, //   referenceSAXFunc
    0, //   charactersSAXFunc
    0, //   ignorableWhitespaceSAXFunc
    0, //   processingInstructionSAXFunc
    0, //   commentSAXFunc
    0, //   warningSAXFunc
    0, //   errorSAXFunc
    0, //   fatalErrorSAXFunc
    0, //   getParameterEntitySAXFunc
    0, //   cdataBlockSAXFunc
    0, //   externalSubsetSAXFunc
    0, //   unsigned int        initialized
    0, //   void *      _private
    0, //   startElementNsSAX2Func
    0, //   endElementNsSAX2Func
    0, //   xmlStructuredErrorFunc
  };
} // namespace

int HtmlParser::parse_chunk(const char *chunk, size_t size, int fin)
{
  if(!parser_ctx_) {
    parser_ctx_ = htmlCreatePushParserCtxt(&saxHandler,
                                           &parser_data_,
                                           chunk, size,
                                           base_uri_.c_str(),
                                           XML_CHAR_ENCODING_NONE);
    if(!parser_ctx_) {
      return -1;
    } else {
      if(fin) {
        return parse_chunk_internal(0, 0, fin);
      } else {
        return 0;
      }
    }
  } else {
    return parse_chunk_internal(chunk, size, fin);
  }
}

int HtmlParser::parse_chunk_internal(const char *chunk, size_t size,
                                     int fin)
{
  int rv = htmlParseChunk(parser_ctx_, chunk, size, fin);
  if(rv == 0) {
    return 0;
  } else {
    return -1;
  }
}

std::vector<std::string>& HtmlParser::get_links()
{
  if (!this->use_assoc_file)
    return parser_data_.links;

  uri::UriStruct us;

  uri::parse(us, this->base_uri_);
  std::string path( us.dir  + us.file);

  std::vector<std::string> *ret = new std::vector<std::string> ();

  if (us.file.length() > 5) {
    if (us.file.substr(us.file.length()-5, 5) == ".html") {
        std::vector<std::string>::iterator it = pushed_links_[path].begin();
        for(; it != pushed_links_[path].end (); it++)
          ret->push_back(*it);
        // delete the link entry
        // TODO HACK this make another request to the same resource impossible
        last_path = path;

    }
  }

  return *ret;

}

void HtmlParser::clear_links()
{
  if (!this->use_assoc_file) {
    parser_data_.links.clear();
  } else {
    this->pushed_links_[last_path].clear();
    // do not provide any links until a chunk is received again
  }

}

} // namespace spdylay
