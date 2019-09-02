// Copyright 2019 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include "audio_core/hle/amf_decoder.h"
#include "audio_core/hle/amf_decoder_utils.h"

namespace AudioCore::HLE {

class AMFDecoder::Impl {
public:
    explicit Impl(Memory::MemorySystem& memory);
    ~Impl();
    std::optional<BinaryResponse> ProcessRequest(const BinaryRequest& request);

private:
    std::optional<BinaryResponse> Initalize(const BinaryRequest& request);

    std::optional<BinaryResponse> Decode(const BinaryRequest& request);

    void Clear();

    int GetFDKInfo();

    Memory::MemorySystem& memory;

    unique_codecptr coder;
    unique_fmtptr out_format;
    bool selected = false;
};

AMFDecoder::Impl::Impl(Memory::MemorySystem& memory) : memory(memory) {}

std::optional<BinaryResponse> AMFDecoder::Impl::Initalize(const BinaryRequest& request) {
    BinaryResponse response;
    std::memcpy(&response, &request, sizeof(response));
    response.unknown1 = 0x0;

    Clear();

    return response;
}

AMFDecoder::Impl::~Impl() {}

void AMFDecoder::Impl::Clear() {
    coder.reset(AMediaCodec_createDecoderByType(ndk_aac_type));
    selected = false;
}

std::optional<BinaryResponse> AMFDecoder::Impl::ProcessRequest(const BinaryRequest& request) {
    if (request.codec != DecoderCodec::AAC) {
        LOG_ERROR(Audio_DSP, "AMF AAC Decoder currently cannot handle such codec: {}",
                  static_cast<u16>(request.codec));
        return {};
    }

    switch (request.cmd) {
    case DecoderCommand::Init: {
        return Initalize(request);
    }
    case DecoderCommand::Decode: {
        return Decode(request);
    }
    case DecoderCommand::Unknown: {
        BinaryResponse response;
        std::memcpy(&response, &request, sizeof(response));
        response.unknown1 = 0x0;
        return response;
    }
    default:
        LOG_ERROR(Audio_DSP, "Got unknown binary request: {}", static_cast<u16>(request.cmd));
        return {};
    }
}

std::optional<BinaryResponse> AMFDecoder::Impl::Decode(const BinaryRequest& request) {
    BinaryResponse response;
    response.codec = request.codec;
    response.cmd = request.cmd;
    response.size = request.size;

    if (request.src_addr < Memory::FCRAM_PADDR ||
        request.src_addr + request.size > Memory::FCRAM_PADDR + Memory::FCRAM_SIZE) {
        LOG_ERROR(Audio_DSP, "Got out of bounds src_addr {:08x}", request.src_addr);
        return {};
    }
    u8* data = memory.GetFCRAMPointer(request.src_addr - Memory::FCRAM_PADDR);

    std::array<std::vector<s16>, 2> out_streams;

    std::size_t data_size = request.size;
    media_status_t status;

    if (!selected) {
        status = SelectInputFormat(coder.get(), data, data_size);
        if (status != AMEDIA_OK) {
            LOG_ERROR(Audio_DSP, "Unable to select input format {:08x}", status);
            return {};
        }
    }

    out_streams = decode_loop(coder, data, data_size);
    if (!out_streams) {
        LOG_ERROR(Audio_DSP, "Unable to decode samples, error is not recoverable");
    }

    // transfer the decoded buffer from vector to the FCRAM
    if (out_streams[0].size() != 0) {
        if (request.dst_addr_ch0 < Memory::FCRAM_PADDR ||
            request.dst_addr_ch0 + out_streams[0].size() >
                Memory::FCRAM_PADDR + Memory::FCRAM_SIZE) {
            LOG_ERROR(Audio_DSP, "Got out of bounds dst_addr_ch0 {:08x}", request.dst_addr_ch0);
            return {};
        }
        std::memcpy(memory.GetFCRAMPointer(request.dst_addr_ch0 - Memory::FCRAM_PADDR),
                    out_streams[0].data(), out_streams[0].size());
    }

    if (out_streams[1].size() != 0) {
        if (request.dst_addr_ch1 < Memory::FCRAM_PADDR ||
            request.dst_addr_ch1 + out_streams[1].size() >
                Memory::FCRAM_PADDR + Memory::FCRAM_SIZE) {
            LOG_ERROR(Audio_DSP, "Got out of bounds dst_addr_ch1 {:08x}", request.dst_addr_ch1);
            return {};
        }
        std::memcpy(memory.GetFCRAMPointer(request.dst_addr_ch1 - Memory::FCRAM_PADDR),
                    out_streams[1].data(), out_streams[1].size());
    }
    return response;
}

AMFDecoder::AMFDecoder(Memory::MemorySystem& memory) : impl(std::make_unique<Impl>(memory)) {}

AMFDecoder::~AMFDecoder() = default;

std::optional<BinaryResponse> AMFDecoder::ProcessRequest(const BinaryRequest& request) {
    return impl->ProcessRequest(request);
}

} // namespace AudioCore::HLE
