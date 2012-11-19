/* (C) 2012 Timo Dörr <timo@latecrew.de>
 * All rights reserved.
 */

#include <stdio.h>

#include "spdylay_associated_content.h"
#include "spdylay_stream.h"

int spdylay_associated_content_register (spdylay_session *session, uint32_t stream_id,
                                        size_t num_assoc_content)
{
    spdylay_stream *stream = spdylay_session_get_stream(session, stream_id);
    if (stream == NULL) {
        return -1;
    }
    stream->assoc_content += num_assoc_content;
    return 0;
}

int spdylay_associated_content_unregister (spdylay_session *session, uint32_t stream_id,
                                           size_t num_assoc_content)
{
    spdylay_stream *stream = spdylay_session_get_stream(session, stream_id);
    if (stream == NULL) {
        return -1;
    }
    stream->assoc_content -= num_assoc_content;
}
