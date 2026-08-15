#include "file_transfer_channel.h"

#include <commdlg.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;

const EncodableValue* FindValue(const EncodableMap& arguments,
                                const std::string& key) {
  const auto iterator = arguments.find(EncodableValue(key));
  return iterator == arguments.end() ? nullptr : &iterator->second;
}

std::optional<std::string> StringArgument(const EncodableMap& arguments,
                                          const std::string& key) {
  const auto* value = FindValue(arguments, key);
  if (value == nullptr) {
    return std::nullopt;
  }
  const auto* string_value = std::get_if<std::string>(value);
  return string_value == nullptr ? std::nullopt
                                 : std::optional<std::string>(*string_value);
}

int64_t IntArgument(const EncodableMap& arguments, const std::string& key,
                    int64_t fallback) {
  const auto* value = FindValue(arguments, key);
  if (value == nullptr) {
    return fallback;
  }
  if (const auto* int_value = std::get_if<int32_t>(value)) {
    return *int_value;
  }
  if (const auto* int_value = std::get_if<int64_t>(value)) {
    return *int_value;
  }
  return fallback;
}

std::vector<std::string> ExtensionsArgument(const EncodableMap& arguments) {
  std::vector<std::string> extensions;
  const auto* value = FindValue(arguments, "allowedExtensions");
  const auto* list = value == nullptr ? nullptr : std::get_if<EncodableList>(value);
  if (list == nullptr) {
    return extensions;
  }
  for (const auto& item : *list) {
    if (const auto* extension = std::get_if<std::string>(&item)) {
      extensions.push_back(*extension);
    }
  }
  return extensions;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int size = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                       static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), size);
  return result;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                       static_cast<int>(value.size()), nullptr, 0,
                                       nullptr, nullptr);
  std::string result(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), size,
                      nullptr, nullptr);
  return result;
}

std::vector<wchar_t> BuildOpenFilter(
    const std::vector<std::string>& extensions) {
  std::wstring patterns;
  for (size_t index = 0; index < extensions.size(); ++index) {
    if (index > 0) {
      patterns.append(L";");
    }
    patterns.append(L"*.");
    patterns.append(Utf8ToWide(extensions[index]));
  }
  if (patterns.empty()) {
    patterns = L"*.*";
  }

  std::vector<wchar_t> filter;
  const auto append = [&filter](const std::wstring& value) {
    filter.insert(filter.end(), value.begin(), value.end());
    filter.push_back(L'\0');
  };
  append(L"Supported files");
  append(patterns);
  append(L"All files");
  append(L"*.*");
  filter.push_back(L'\0');
  return filter;
}

void CompleteDialogFailure(std::unique_ptr<MethodResult<EncodableValue>> result,
                           const std::string& operation) {
  const DWORD error = CommDlgExtendedError();
  if (error == 0) {
    result->Success();
    return;
  }
  result->Error("file_dialog_failed",
                "The Windows " + operation + " dialog could not be opened.");
}

void PickFile(HWND owner, const EncodableMap& arguments,
              std::unique_ptr<MethodResult<EncodableValue>> result) {
  const auto extensions = ExtensionsArgument(arguments);
  auto filter = BuildOpenFilter(extensions);
  std::vector<wchar_t> file_buffer(32768, L'\0');

  OPENFILENAMEW dialog{};
  dialog.lStructSize = sizeof(dialog);
  dialog.hwndOwner = owner;
  dialog.lpstrFilter = filter.data();
  dialog.lpstrFile = file_buffer.data();
  dialog.nMaxFile = static_cast<DWORD>(file_buffer.size());
  dialog.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
                 OFN_NOCHANGEDIR;

  if (!GetOpenFileNameW(&dialog)) {
    CompleteDialogFailure(std::move(result), "open-file");
    return;
  }

  const std::filesystem::path path(file_buffer.data());
  std::ifstream input(path, std::ios::binary | std::ios::ate);
  if (!input) {
    result->Error("file_read_failed", "The selected file could not be read.");
    return;
  }
  const auto size = input.tellg();
  const int64_t max_bytes = IntArgument(arguments, "maxBytes", 10 * 1024 * 1024);
  if (size < 0 || size > max_bytes) {
    result->Error("file_too_large", "The selected file exceeds the size limit.");
    return;
  }

  std::vector<uint8_t> bytes(static_cast<size_t>(size));
  input.seekg(0, std::ios::beg);
  if (!bytes.empty()) {
    input.read(reinterpret_cast<char*>(bytes.data()),
               static_cast<std::streamsize>(size));
  }
  if (!input) {
    result->Error("file_read_failed", "The selected file could not be read.");
    return;
  }

  EncodableMap response;
  response[EncodableValue("name")] =
      EncodableValue(WideToUtf8(path.filename().wstring()));
  response[EncodableValue("bytes")] = EncodableValue(bytes);
  result->Success(EncodableValue(response));
}

void SaveFile(HWND owner, const EncodableMap& arguments,
              std::unique_ptr<MethodResult<EncodableValue>> result) {
  const auto file_name = StringArgument(arguments, "name");
  const auto* bytes_value = FindValue(arguments, "bytes");
  const auto* bytes =
      bytes_value == nullptr ? nullptr : std::get_if<std::vector<uint8_t>>(bytes_value);
  if (!file_name.has_value() || bytes == nullptr) {
    result->Error("invalid_arguments", "The export file is invalid.");
    return;
  }

  const auto wide_name = Utf8ToWide(*file_name);
  std::vector<wchar_t> file_buffer(32768, L'\0');
  const auto copy_length =
      (std::min)(wide_name.size(), file_buffer.size() - 1);
  std::copy_n(wide_name.begin(), copy_length, file_buffer.begin());

  const auto extension = std::filesystem::path(wide_name).extension().wstring();
  const std::wstring clean_extension =
      extension.empty() ? std::wstring() : extension.substr(1);
  auto filter = BuildOpenFilter(
      clean_extension.empty()
          ? std::vector<std::string>()
          : std::vector<std::string>{WideToUtf8(clean_extension)});

  OPENFILENAMEW dialog{};
  dialog.lStructSize = sizeof(dialog);
  dialog.hwndOwner = owner;
  dialog.lpstrFilter = filter.data();
  dialog.lpstrFile = file_buffer.data();
  dialog.nMaxFile = static_cast<DWORD>(file_buffer.size());
  dialog.lpstrDefExt = clean_extension.empty() ? nullptr : clean_extension.c_str();
  dialog.Flags = OFN_EXPLORER | OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST |
                 OFN_NOCHANGEDIR;

  if (!GetSaveFileNameW(&dialog)) {
    CompleteDialogFailure(std::move(result), "save-file");
    return;
  }

  std::ofstream output(std::filesystem::path(file_buffer.data()),
                       std::ios::binary | std::ios::trunc);
  if (!output) {
    result->Error("file_write_failed", "The selected file could not be saved.");
    return;
  }
  if (!bytes->empty()) {
    output.write(reinterpret_cast<const char*>(bytes->data()),
                 static_cast<std::streamsize>(bytes->size()));
  }
  if (!output) {
    result->Error("file_write_failed", "The selected file could not be saved.");
    return;
  }
  result->Success(EncodableValue(true));
}

}  // namespace

FileTransferChannel::FileTransferChannel(flutter::FlutterEngine* engine,
                                         HWND owner) {
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "episode/file_transfer",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [owner](const MethodCall<EncodableValue>& call,
              std::unique_ptr<MethodResult<EncodableValue>> result) {
        const auto* arguments = std::get_if<EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "File dialog arguments are missing.");
          return;
        }
        if (call.method_name() == "pickFile") {
          PickFile(owner, *arguments, std::move(result));
        } else if (call.method_name() == "saveFile") {
          SaveFile(owner, *arguments, std::move(result));
        } else {
          result->NotImplemented();
        }
      });
}

FileTransferChannel::~FileTransferChannel() = default;
