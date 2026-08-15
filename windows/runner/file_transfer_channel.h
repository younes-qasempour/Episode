#ifndef RUNNER_FILE_TRANSFER_CHANNEL_H_
#define RUNNER_FILE_TRANSFER_CHANNEL_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

class FileTransferChannel {
 public:
  FileTransferChannel(flutter::FlutterEngine* engine, HWND owner);
  ~FileTransferChannel();

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_FILE_TRANSFER_CHANNEL_H_
