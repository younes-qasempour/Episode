#ifndef RUNNER_COMPAT_ATLSTR_H_
#define RUNNER_COMPAT_ATLSTR_H_

#include <windows.h>

#include <stdexcept>
#include <string>

// flutter_secure_storage_windows only relies on CA2W/CW2A and their m_psz
// members. Keeping that tiny surface local avoids requiring the optional ATL
// workload solely for UTF conversion.
namespace episode_compat {

inline std::wstring Utf8ToWide(const char* input) {
  if (input == nullptr || *input == '\0') {
    return {};
  }

  const int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, input,
                                         -1, nullptr, 0);
  if (length == 0) {
    throw std::runtime_error("Unable to convert UTF-8 text to UTF-16.");
  }

  std::wstring output(static_cast<size_t>(length), L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, input, -1, output.data(),
                      length);
  output.resize(static_cast<size_t>(length - 1));
  return output;
}

inline std::string WideToUtf8(const wchar_t* input) {
  if (input == nullptr || *input == L'\0') {
    return {};
  }

  const int length = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, input,
                                         -1, nullptr, 0, nullptr, nullptr);
  if (length == 0) {
    throw std::runtime_error("Unable to convert UTF-16 text to UTF-8.");
  }

  std::string output(static_cast<size_t>(length), '\0');
  WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, input, -1, output.data(),
                      length, nullptr, nullptr);
  output.resize(static_cast<size_t>(length - 1));
  return output;
}

}  // namespace episode_compat

class CA2W {
 public:
  explicit CA2W(const char* input) : value_(episode_compat::Utf8ToWide(input)) {
    m_psz = value_.data();
  }

  operator const wchar_t*() const { return m_psz; }

  wchar_t* m_psz;

 private:
  std::wstring value_;
};

class CW2A {
 public:
  explicit CW2A(const wchar_t* input)
      : value_(episode_compat::WideToUtf8(input)) {
    m_psz = value_.data();
  }

  operator const char*() const { return m_psz; }

  char* m_psz;

 private:
  std::string value_;
};

#endif  // RUNNER_COMPAT_ATLSTR_H_
