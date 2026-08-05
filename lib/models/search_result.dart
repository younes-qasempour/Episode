enum SearchFailureType {
  network,
  timeout,
  rateLimited,
  server,
  invalidResponse,
  unknown,
}

sealed class SearchResult<T> {
  const SearchResult();
}

final class SearchSuccess<T> extends SearchResult<T> {
  final T data;
  const SearchSuccess(this.data);
}

final class SearchFailure<T> extends SearchResult<T> {
  final SearchFailureType type;
  final String? technicalMessage;
  final int? statusCode;

  const SearchFailure({
    required this.type,
    this.technicalMessage,
    this.statusCode,
  });
}
