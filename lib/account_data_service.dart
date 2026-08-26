import 'dart:convert';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

typedef ExcelPasswordRequest = Future<String?> Function(String? errorMessage);

class AccountImportException implements Exception {
  const AccountImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _InvalidExcelPasswordException implements Exception {
  const _InvalidExcelPasswordException();
}

class _PickedDocument {
  const _PickedDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class AccountFilePreview {
  const AccountFilePreview({
    required this.transactions,
    required this.skippedRows,
    this.balance,
  });

  final List<MoneyTransaction> transactions;
  final int skippedRows;
  final int? balance;
}

class _NativeTransactions {
  const _NativeTransactions({required this.transactions, this.balance});

  final List<MoneyTransaction> transactions;
  final int? balance;
}

class AccountDataService {
  AccountDataService();

  static const _channel = MethodChannel(
    'com.ibm.money.ibm_money_app/account_data',
  );
  static const _storageKey = 'account_data_v1';

  SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  Future<AccountData?> loadSaved() async {
    try {
      final raw = await _preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['transactions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_transactionFromJson)
          .toList();
      var recategorized = false;
      final migratedItems = items.map((item) {
        if (item.category != '기타') return item;
        final category = categorizeMerchant(item.merchant);
        if (category == '기타') return item;
        recategorized = true;
        return MoneyTransaction(
          id: item.id,
          merchant: item.merchant,
          category: category,
          amount: item.amount,
          date: item.date,
        );
      }).toList();
      final data = AccountData(
        balance: (json['balance'] as num?)?.round() ?? 0,
        transactions: migratedItems,
        isDemo: false,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? ''),
      );
      if (recategorized) await save(data);
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AccountData data) async {
    final json = <String, dynamic>{
      'balance': data.balance,
      'lastUpdated': data.lastUpdated?.toIso8601String(),
      'transactions': data.transactions.map(_transactionToJson).toList(),
    };
    await _preferences.setString(_storageKey, jsonEncode(json));
  }

  Future<({AccountData data, int imported, int skipped})?> importDocument(
    AccountData current, {
    ExcelPasswordRequest? requestPassword,
  }) async {
    final picked = await _pickDocument();
    if (picked == null) return null;
    var documentBytes = picked.bytes;
    if (_isPasswordProtectedXlsx(picked.name, documentBytes)) {
      if (requestPassword == null) {
        throw const AccountImportException('이 엑셀 파일은 비밀번호로 보호되어 있어요.');
      }
      String? passwordError;
      while (true) {
        final password = await requestPassword(passwordError);
        if (password == null) return null;
        if (password.isEmpty) {
          passwordError = '비밀번호를 입력해 주세요.';
          continue;
        }
        try {
          documentBytes = await _decryptExcel(documentBytes, password);
          break;
        } on _InvalidExcelPasswordException {
          passwordError = '비밀번호가 맞지 않아요. 다시 입력해 주세요.';
        }
      }
    }
    final parsed = parseDocument(name: picked.name, bytes: documentBytes);
    if (parsed.transactions.isEmpty) {
      throw const AccountImportException(
        '지출 내역을 찾지 못했어요. 날짜, 거래내용, 출금금액 열이 있는 파일인지 확인해 주세요.',
      );
    }
    final base = current.isDemo ? <MoneyTransaction>[] : current.transactions;
    final merged = _mergeTransactions(base, parsed.transactions);
    final updated = AccountData(
      balance: parsed.balance ?? (current.isDemo ? 0 : current.balance),
      transactions: merged,
      isDemo: false,
      lastUpdated: DateTime.now(),
    );
    await save(updated);
    return (
      data: updated,
      imported: parsed.transactions.length,
      skipped: parsed.skippedRows,
    );
  }

  Future<({AccountData data, int added})> syncNotifications(
    AccountData current,
  ) async {
    final native = await _readNativeTransactions();
    if (native.transactions.isEmpty && native.balance == null) {
      return (data: current, added: 0);
    }
    final base = current.isDemo ? <MoneyTransaction>[] : current.transactions;
    final knownIds = base.map((item) => item.id).toSet();
    final added = native.transactions
        .where((item) => !knownIds.contains(item.id))
        .length;
    final updated = AccountData(
      balance: native.balance ?? (current.isDemo ? 0 : current.balance),
      transactions: _mergeTransactions(base, native.transactions),
      isDemo: false,
      lastUpdated: DateTime.now(),
    );
    await save(updated);
    return (data: updated, added: added);
  }

  Future<bool> isNotificationAccessGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isNotificationAccessGranted') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openNotificationAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationAccessSettings');
    } on MissingPluginException {
      throw const AccountImportException('알림 자동 등록은 Android 휴대폰에서만 사용할 수 있어요.');
    }
  }

  Future<_PickedDocument?> _pickDocument() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'pickTransactionFile',
      );
      if (raw == null) return null;
      final bytes = raw['bytes'];
      if (bytes is! Uint8List || bytes.isEmpty) {
        throw const AccountImportException('선택한 파일을 읽을 수 없어요.');
      }
      return _PickedDocument(
        name: raw['name']?.toString() ?? '거래내역',
        bytes: bytes,
      );
    } on MissingPluginException {
      throw const AccountImportException('거래내역 가져오기는 Android 휴대폰에서 사용해 주세요.');
    } on PlatformException catch (error) {
      if (error.code == 'PICK_CANCELLED') return null;
      throw AccountImportException(error.message ?? '파일을 열지 못했어요.');
    }
  }

  bool _isPasswordProtectedXlsx(String name, Uint8List bytes) {
    const compoundHeader = [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1];
    if (!name.toLowerCase().endsWith('.xlsx') || bytes.length < 8) {
      return false;
    }
    for (var index = 0; index < compoundHeader.length; index++) {
      if (bytes[index] != compoundHeader[index]) return false;
    }
    return true;
  }

  Future<Uint8List> _decryptExcel(Uint8List bytes, String password) async {
    try {
      final decrypted = await _channel.invokeMethod<Uint8List>('decryptExcel', {
        'bytes': bytes,
        'password': password,
      });
      if (decrypted == null || decrypted.length < 4) {
        throw const AccountImportException('암호화된 엑셀 파일을 열지 못했어요.');
      }
      return decrypted;
    } on MissingPluginException {
      throw const AccountImportException(
        '암호화된 엑셀 가져오기는 Android 휴대폰에서 사용해 주세요.',
      );
    } on PlatformException catch (error) {
      if (error.code == 'BAD_PASSWORD') {
        throw const _InvalidExcelPasswordException();
      }
      throw AccountImportException(error.message ?? '암호화된 엑셀 파일을 열지 못했어요.');
    }
  }

  Future<_NativeTransactions> _readNativeTransactions() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCapturedTransactions',
      );
      if (raw == null) return const _NativeTransactions(transactions: []);
      final rows = raw['transactions'] as List<Object?>? ?? const [];
      final transactions = <MoneyTransaction>[];
      for (final row in rows) {
        if (row is! Map<Object?, Object?>) continue;
        final amount = (row['amount'] as num?)?.round() ?? 0;
        final timestamp = (row['timestamp'] as num?)?.round() ?? 0;
        final merchant = row['merchant']?.toString().trim() ?? '';
        if (amount <= 0 || timestamp <= 0 || merchant.isEmpty) continue;
        transactions.add(
          MoneyTransaction(
            id: row['id']?.toString() ?? 'toss-$timestamp-$amount',
            merchant: _cleanMerchant(merchant),
            category: categorizeMerchant(merchant),
            amount: amount,
            date: DateTime.fromMillisecondsSinceEpoch(timestamp),
          ),
        );
      }
      return _NativeTransactions(
        transactions: transactions,
        balance: (raw['balance'] as num?)?.round(),
      );
    } on MissingPluginException {
      return const _NativeTransactions(transactions: []);
    } on PlatformException {
      return const _NativeTransactions(transactions: []);
    }
  }

  AccountFilePreview parseDocument({
    required String name,
    required Uint8List bytes,
  }) {
    final lowerName = name.toLowerCase();
    final rows = lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')
        ? _rowsFromExcel(bytes)
        : _rowsFromText(bytes);
    return _parseRows(rows);
  }

  List<List<String>> _rowsFromExcel(Uint8List bytes) {
    try {
      final workbook = Excel.decodeBytes(bytes);
      for (final sheet in workbook.tables.values) {
        final rows = sheet.rows
            .map(
              (row) =>
                  row.map((cell) => _excelValueToString(cell?.value)).toList(),
            )
            .where((row) => row.any((value) => value.trim().isNotEmpty))
            .toList();
        if (_findHeaderRow(rows) != null) return rows;
      }
      throw const AccountImportException('엑셀 파일에서 거래내역 표를 찾지 못했어요.');
    } catch (error) {
      if (error is AccountImportException) rethrow;
      final message = error.toString().toLowerCase();
      if (message.contains('password') ||
          message.contains('encrypted') ||
          message.contains('암호')) {
        throw const AccountImportException(
          '암호가 설정된 엑셀 파일은 읽을 수 없어요. '
          '암호 없이 .xlsx로 다시 저장해 주세요.',
        );
      }
      throw const AccountImportException(
        '이 엑셀 파일 형식을 읽지 못했어요. '
        '파일 이름이 .xls 또는 .xlsx로 끝나는지 확인해 주세요.',
      );
    }
  }

  String _excelValueToString(CellValue? value) {
    return switch (value) {
      null => '',
      TextCellValue() => value.value.toString(),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
      _ => value.toString(),
    };
  }

  List<List<String>> _rowsFromText(Uint8List bytes) {
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = utf8.decode(bytes, allowMalformed: true);
    }
    text = text.replaceFirst('\ufeff', '');
    final lines = const LineSplitter().convert(text);
    final tabCount = lines
        .take(5)
        .fold<int>(0, (count, line) => count + '\t'.allMatches(line).length);
    final commaCount = lines
        .take(5)
        .fold<int>(0, (count, line) => count + ','.allMatches(line).length);
    final delimiter = tabCount > commaCount ? '\t' : ',';
    return lines
        .map((line) => _splitDelimitedLine(line, delimiter))
        .where((row) => row.any((value) => value.trim().isNotEmpty))
        .toList();
  }

  List<String> _splitDelimitedLine(String line, String delimiter) {
    final values = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == delimiter && !quoted) {
        values.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }
    values.add(buffer.toString().trim());
    return values;
  }

  AccountFilePreview _parseRows(List<List<String>> rows) {
    final headerIndex = _findHeaderRow(rows);
    if (headerIndex == null) {
      throw const AccountImportException(
        '열 이름을 확인할 수 없어요. 날짜, 거래내용, 출금금액 열이 필요해요.',
      );
    }
    final header = rows[headerIndex].map(_normalizeHeader).toList();
    final dateIndex = _findColumn(header, const [
      '거래일시',
      '거래일자',
      '거래일',
      '일시',
      '날짜',
    ]);
    final merchantIndex = _findColumn(header, const [
      '거래내용',
      '거래처',
      '적요',
      '상호명',
      '사용처',
      '받는분',
      '내용',
    ]);
    final outflowIndex = _findColumn(header, const [
      '출금금액',
      '지출금액',
      '사용금액',
      '결제금액',
      '출금',
      '지출',
    ]);
    final amountIndex =
        outflowIndex ?? _findColumn(header, const ['거래금액', '금액', '이용금액']);
    final typeIndex = _findColumn(header, const ['거래구분', '입출금구분', '구분', '유형']);
    final institutionIndex = _findColumn(header, const [
      '거래기관',
      '금융기관',
      '기관',
      '은행',
    ]);
    final memoIndex = _findColumn(header, const ['메모', '비고', '사용자메모']);
    final balanceIndex = _findColumn(header, const ['거래후잔액', '거래후금액', '잔액']);
    final categoryIndex = _findColumn(header, const ['카테고리', '분류']);
    if (dateIndex == null || merchantIndex == null || amountIndex == null) {
      throw const AccountImportException(
        '날짜, 거래내용, 출금금액 열을 모두 찾을 수 있는 파일이 필요해요.',
      );
    }

    final transactions = <MoneyTransaction>[];
    var skipped = 0;
    int? latestBalance;
    DateTime? latestBalanceDate;
    for (var index = headerIndex + 1; index < rows.length; index++) {
      final row = rows[index];
      String valueAt(int? column) =>
          column == null || column >= row.length ? '' : row[column].trim();
      final date = _parseDate(valueAt(dateIndex));
      final description = valueAt(merchantIndex);
      final institution = valueAt(institutionIndex);
      final memo = valueAt(memoIndex);
      final merchant = _cleanMerchant(memo.isNotEmpty ? memo : description);
      final amountText = valueAt(amountIndex);
      final amount = _parseAmount(amountText);
      final type = valueAt(typeIndex);
      final isDeposit =
          type.contains('입금') ||
          type.contains('환불') ||
          type.contains('취소') ||
          (outflowIndex == null && amountText.trim().startsWith('+'));
      if (date == null || merchant.isEmpty || amount == null || amount == 0) {
        if (row.any((value) => value.trim().isNotEmpty)) skipped++;
        continue;
      }
      final balance = _parseAmount(valueAt(balanceIndex));
      if (balance != null &&
          (latestBalanceDate == null || date.isAfter(latestBalanceDate))) {
        latestBalance = balance;
        latestBalanceDate = date;
      }
      if (isDeposit) continue;
      final category = valueAt(categoryIndex).isEmpty
          ? _categorizeTransaction(
              merchant: merchant,
              type: type,
              institution: institution,
              memo: memo,
            )
          : valueAt(categoryIndex);
      transactions.add(
        MoneyTransaction(
          id: _transactionId('import', date, merchant, amount.abs()),
          merchant: merchant,
          category: category,
          amount: amount.abs(),
          date: date,
        ),
      );
    }
    return AccountFilePreview(
      transactions: _mergeTransactions(const [], transactions),
      skippedRows: skipped,
      balance: latestBalance,
    );
  }

  int? _findHeaderRow(List<List<String>> rows) {
    for (var index = 0; index < rows.length && index < 25; index++) {
      final header = rows[index].map(_normalizeHeader).toList();
      final hasDate =
          _findColumn(header, const ['거래일시', '거래일자', '거래일', '날짜', '일시']) !=
          null;
      final hasMerchant =
          _findColumn(header, const [
            '거래내용',
            '거래처',
            '적요',
            '상호명',
            '사용처',
            '내용',
          ]) !=
          null;
      final hasAmount =
          _findColumn(header, const [
            '출금금액',
            '지출금액',
            '사용금액',
            '결제금액',
            '거래금액',
            '금액',
          ]) !=
          null;
      if (hasDate && hasMerchant && hasAmount) return index;
    }
    return null;
  }

  int? _findColumn(List<String> headers, List<String> aliases) {
    final normalizedAliases = aliases.map(_normalizeHeader).toList();
    for (final alias in normalizedAliases) {
      final exact = headers.indexOf(alias);
      if (exact != -1) return exact;
    }
    for (var index = 0; index < headers.length; index++) {
      if (normalizedAliases.any((alias) => headers[index].contains(alias))) {
        return index;
      }
    }
    return null;
  }

  String _normalizeHeader(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_\-./()\[\]]'), '');

  DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final normalized = raw
        .replaceAll('년', '-')
        .replaceAll('월', '-')
        .replaceAll('일', ' ')
        .replaceAll('.', '-')
        .replaceAll('/', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;
    final match = RegExp(
      r'^(\d{2,4})-(\d{1,2})-(\d{1,2})(?:\s+(오전|오후)?\s*(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(normalized);
    if (match != null) {
      var year = int.parse(match.group(1)!);
      if (year < 100) year += 2000;
      var hour = int.tryParse(match.group(5) ?? '') ?? 0;
      if (match.group(4) == '오후' && hour < 12) hour += 12;
      if (match.group(4) == '오전' && hour == 12) hour = 0;
      return DateTime(
        year,
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        hour,
        int.tryParse(match.group(6) ?? '') ?? 0,
        int.tryParse(match.group(7) ?? '') ?? 0,
      );
    }
    return null;
  }

  int? _parseAmount(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '-') return null;
    final negative =
        raw.contains('-') || (raw.contains('(') && raw.contains(')'));
    final digits = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) return null;
    final parsed = double.tryParse(digits)?.round();
    if (parsed == null) return null;
    return negative ? -parsed : parsed;
  }

  static String categorizeMerchant(String merchant) {
    final value = _normalizeMerchant(merchant);
    if (_containsAny(value, const [
      '배달',
      '배민',
      '요기요',
      '쿠팡이츠',
      '땡겨요',
      '우아한형제',
    ])) {
      return '배달';
    }
    if (_containsAny(value, const [
      '카페',
      '커피',
      '스타벅스',
      '투썸',
      '메가커피',
      '메가엠지씨',
      '이디야',
      '컴포즈',
      '빽다방',
      '공차',
      '할리스',
      '파스쿠찌',
      '더벤티',
      '매머드',
    ])) {
      return '카페';
    }
    if (_containsAny(value, const [
      '넷플릭스',
      '유튜브',
      '디즈니',
      '왓챠',
      '멜론',
      '스포티파이',
      '네이버플러스',
      '쿠팡와우',
      '애플뮤직',
      '구글원',
      '구독',
    ])) {
      return '구독';
    }
    if (_containsAny(value, const [
      '버스',
      '지하철',
      '택시',
      '카카오t',
      '티머니',
      '캐시비',
      '코레일',
      'ktx',
      'srt',
      '후불교통',
      '주유',
      '주차',
      '통행료',
      '교통',
    ])) {
      return '교통';
    }
    if (_containsAny(value, const [
      '병원',
      '의원',
      '약국',
      '치과',
      '한의원',
      '안과',
      '피부과',
    ])) {
      return '의료';
    }
    if (_containsAny(value, const [
      '영화',
      'cgv',
      '메가박스',
      '롯데시네마',
      '노래방',
      'pc방',
      '게임',
      '문화',
      '공연',
      '티켓',
      '레저',
    ])) {
      return '여가';
    }
    if (_containsAny(value, const [
      '통신',
      '전기',
      '가스',
      '수도',
      '관리비',
      '보험',
      '세탁',
      '미용',
      '헤어',
      '네일',
      '학원',
      '교육',
      '렌탈',
      '정비',
      '수리',
    ])) {
      return '생활';
    }
    if (_containsAny(value, const [
      '쿠팡',
      '네이버페이',
      '11번가',
      '지마켓',
      '옥션',
      '무신사',
      '올리브영',
      '다이소',
      '마켓컬리',
      '오늘의집',
      '알리익스프레스',
      '에이블리',
      '지그재그',
      '테무',
      '백화점',
      '아울렛',
      '스토어',
      '쇼핑몰',
      '문구',
      '서점',
      '쇼핑',
    ])) {
      return '쇼핑';
    }
    if (_containsAny(value, const [
      '편의점',
      'gs25',
      'cu',
      '세븐일레븐',
      '이마트',
      '홈플러스',
      '롯데마트',
      '마트',
      '식당',
      '푸드',
      '치킨',
      '피자',
      '버거',
      '맥도날드',
      '롯데리아',
      '맘스터치',
      '김밥',
      '국밥',
      '분식',
      '베이커리',
      '파리바게뜨',
      '뚜레쥬르',
      '제과',
      '떡',
      '국수',
      '냉면',
      '고기',
      '갈비',
      '곱창',
      '족발',
      '보쌈',
      '포차',
      '주점',
      '스시',
      '초밥',
      '횟집',
      '수산',
      '샤브',
      '한솥',
      '반찬',
    ])) {
      return '식비';
    }
    return '기타';
  }

  static String _categorizeTransaction({
    required String merchant,
    required String type,
    required String institution,
    required String memo,
  }) {
    final direct = categorizeMerchant('$merchant $memo');
    if (direct != '기타') return direct;

    final normalizedInstitution = _normalizeMerchant(institution);
    final normalizedDetails = _normalizeMerchant('$merchant $type $memo');
    final isBankTransfer =
        _containsAny(normalizedInstitution, const [
          '은행',
          '뱅크',
          '저축은행',
          '새마을금고',
          '신협',
          '증권',
        ]) &&
        !_containsAny(normalizedDetails, const ['카드결제', '체크카드']);
    if (isBankTransfer ||
        _containsAny(normalizedDetails, const ['송금', '계좌이체', '간편송금'])) {
      return '이체';
    }
    if (_containsAny(normalizedDetails, const ['atm', '현금인출', '현금출금'])) {
      return '현금';
    }
    return '기타';
  }

  static String _normalizeMerchant(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'(주식회사|유한회사|\(주\)|㈜)'), '')
      .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');

  static bool _containsAny(String value, List<String> keywords) =>
      keywords.any(value.contains);

  static String _cleanMerchant(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'\[[^\]]+\]'), ' ')
        .replaceAll(RegExp(r'\b\d{2,4}[-*]\d{2,4}[-*]\d{2,6}\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? '토스뱅크 거래' : cleaned;
  }

  static String _transactionId(
    String source,
    DateTime date,
    String merchant,
    int amount,
  ) {
    var hash = 2166136261;
    for (final unit in '$merchant|$amount'.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
    }
    return '$source-${date.millisecondsSinceEpoch}-$hash';
  }

  static List<MoneyTransaction> _mergeTransactions(
    List<MoneyTransaction> first,
    List<MoneyTransaction> second,
  ) {
    final merged = <String, MoneyTransaction>{};
    for (final item in [...first, ...second]) {
      merged[item.id] = item;
    }
    final result = merged.values.toList()
      ..sort((left, right) => right.date.compareTo(left.date));
    return result;
  }

  static Map<String, dynamic> _transactionToJson(MoneyTransaction item) => {
    'id': item.id,
    'merchant': item.merchant,
    'category': item.category,
    'amount': item.amount,
    'date': item.date.toIso8601String(),
  };

  static MoneyTransaction _transactionFromJson(Map<String, dynamic> json) {
    return MoneyTransaction(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).round(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
