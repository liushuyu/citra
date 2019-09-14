// Copyright 2019 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "amf_decoder_utils.h"

std::optional<std::vector<u8>> decode_loop(AMediaCodec* coder, const char* buffer,
                                                size_t buffer_size) {
    media_status_t status;
    u8* in_buffer = NULL;
    u8* out_buffer = NULL;
    ssize_t in_queue_id = 0;
    ssize_t out_queue_id = 0;
    size_t out_size = 0;
    AMediaCodecBufferInfo buffer_info;
    std::optional<std::vector<u8>> result;

    // actual decoding loop
    // get the queue ID for queuing our next buffer
    // use of -1: wait until codec is ready
    in_queue_id = AMediaCodec_dequeueInputBuffer(coder, -1);
    // fetch input buffer
    // according to my observation, the framework will allocate ~30k space for you
    in_buffer = AMediaCodec_getInputBuffer(coder, in_queue_id, &out_size);
    // copy our buffer to framework provided space
    std::memcpy(in_buffer, buffer, buffer_size);
    // submit the buffer for processing
    // note that we specify the input size here and we get the output status here
    status = AMediaCodec_queueInputBuffer(coder, in_queue_id, 0, buffer_size, 0, 0);
    if (status != AMEDIA_OK) {
        // format change
        if (status == AMEDIA_ERROR_INVALID_PARAMETER) {
            status = SelectInputFormat(coder, buffer, buffer_size);
            if (status != AMEDIA_OK)
                return {};                                  // not recoverable
            return decode_loop(coder, buffer, buffer_size); // try again
        }
        return {}; // codec error
    }
    // get the output buffer from queue
    // the out_size here is actually much larger comparing to
    // the actual data size which we can only get later
    out_buffer = AMediaCodec_getOutputBuffer(coder, out_queue_id,
                                             &out_size); // this step will free the input
                                                         // buffer (by NDK Media framework)
    // dequeuing the output buffer won't cause the framework to collect the
    // output buffer, we will collect the buffer after copying the data
    // to a safe place
    out_queue_id = AMediaCodec_dequeueOutputBuffer(coder, &buffer_info, -1);
    // decoding loop end
    result->reserve(buffer_info.size);
    // copy data over, note that the actual size is in buffer_info
    std::memcpy(result->data(), out_buffer, buffer_info.size);
    // release the buffer
    // the meaning of the third parameter:
    // whether to update the framebuffer on the registered video surface
    // we are decoding audio so obviously not updating fb
    AMediaCodec_releaseOutputBuffer(coder, out_queue_id, false);
    return result;
}

unique_fmtptr DetectFormat(const char* buffer, std::size_t len) {
    // the length of the header
    if (len < 7) {
        return nullptr;
    }

    unique_fmtptr format(AMediaFormat_new());
    ADTSData adts = ParseADTS(buffer);
    // Thank god, very self-explanatory parameters here
    AMediaFormat_setInt32(format.get(), "is-adts", 1);
    AMediaFormat_setString(format.get(), "mime", ndk_aac_type);
    AMediaFormat_setInt32(format.get(), "sample-rate", adts.samplerate);
    AMediaFormat_setInt32(format.get(), "channel-count", adts.channels);
    return format;
}

inline media_status_t SelectInputFormat(AMediaCodec* coder, const char* buffer,
                                        size_t buffer_size) {
    unique_fmtptr format;
    media_status_t status = AMEDIA_OK;

    format = DetectFormat(buffer, buffer_size);
    status = AMediaCodec_configure(coder, format.get(), NULL, NULL, 0);
    return status;
}
