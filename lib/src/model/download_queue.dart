class DownloadQueue {
  final String url;
  final Map<String, String>? headers;
  final String? key;

  DownloadQueue({required this.url, this.headers, this.key});
}
