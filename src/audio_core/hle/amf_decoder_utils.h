#include <cstring>
#include <iostream>
#include <memory>
#include <optional>
#include <vector>

#include <media/NdkMediaCodec.h>
#include <media/NdkMediaFormat.h>

#include "audio_core/hle/decoder.h"

#include "adts.h"

// some vendor may have different string (which is against the standard)
// and won't pass Android CTS
const char* ndk_aac_type = "audio/mp4a-latm";
// utility functions / templates
struct AMediaFormatRelease {
    void operator()(AMediaFormat* format) const {
        AMediaFormat_delete(format);
    };
};

struct AMediaCodecRelease {
    void operator()(AMediaCodec* pointer) const {
        AMediaCodec_stop(pointer);
        AMediaCodec_delete(pointer);
    };
};

using unique_codecptr = std::unique_ptr<AMediaCodec, AMediaCodecRelease>;
using unique_fmtptr = std::unique_ptr<AMediaFormat, AMediaFormatRelease>;

std::optional<std::vector<uint8_t>> decode_loop(AMediaCodec* coder, const char* buffer,
                                                size_t buffer_size);
unique_fmtptr DetectFormat(const char* buffer, std::size_t len);
media_status_t SelectInputFormat(AMediaCodec* coder, const char* buffer, size_t buffer_size);
