import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/account_data_service.dart';

void main() {
  test('imports Toss-style Excel transaction statement', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    sheet.appendRow([
      TextCellValue('거래일시'),
      TextCellValue('거래내용'),
      TextCellValue('거래구분'),
      TextCellValue('출금금액'),
      TextCellValue('입금금액'),
      TextCellValue('거래 후 잔액'),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-25 14:32'),
      TextCellValue('스타벅스 강남점'),
      TextCellValue('출금'),
      IntCellValue(5500),
      null,
      IntCellValue(257230),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-24 10:00'),
      TextCellValue('급여'),
      TextCellValue('입금'),
      null,
      IntCellValue(1000000),
      IntCellValue(262730),
    ]);

    final bytes = Uint8List.fromList(workbook.encode()!);
    final result = AccountDataService().parseDocument(
      name: '토스뱅크_거래내역.xlsx',
      bytes: bytes,
    );

    expect(result.transactions, hasLength(1));
    expect(result.transactions.single.merchant, '스타벅스 강남점');
    expect(result.transactions.single.amount, 5500);
    expect(result.transactions.single.category, '카페');
    expect(result.balance, 257230);
  });

  test('classifies Toss rows using description, type, and institution', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];
    sheet.appendRow([TextCellValue('토스뱅크 거래내역')]);
    sheet.appendRow([TextCellValue('조회 기간'), TextCellValue('2026-08')]);
    sheet.appendRow([
      TextCellValue('거래 일시'),
      TextCellValue('적요'),
      TextCellValue('거래 유형'),
      TextCellValue('거래 기관'),
      TextCellValue('계좌번호'),
      TextCellValue('거래 금액'),
      TextCellValue('거래 후 잔액'),
      TextCellValue('메모'),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-25 14:32'),
      TextCellValue('메가엠지씨커피 역삼점'),
      TextCellValue('체크카드 출금'),
      TextCellValue('토스뱅크'),
      TextCellValue('0000'),
      IntCellValue(-5500),
      IntCellValue(257230),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-24 10:00'),
      TextCellValue('친구에게 보냄'),
      TextCellValue('출금'),
      TextCellValue('가나다은행'),
      TextCellValue('1111'),
      IntCellValue(-30000),
      IntCellValue(262730),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-23 09:10'),
      TextCellValue('우리동네의원'),
      TextCellValue('체크카드 출금'),
      TextCellValue('토스뱅크'),
      TextCellValue('0000'),
      IntCellValue(-12000),
      IntCellValue(292730),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-22 18:20'),
      TextCellValue('메가박스'),
      TextCellValue('체크카드 출금'),
      TextCellValue('토스뱅크'),
      TextCellValue('0000'),
      IntCellValue(-15000),
      IntCellValue(304730),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('2026-08-21 12:00'),
      TextCellValue('급여'),
      TextCellValue('입금'),
      TextCellValue('가나다은행'),
      TextCellValue('1111'),
      IntCellValue(1000000),
      IntCellValue(319730),
      TextCellValue(''),
    ]);

    final bytes = Uint8List.fromList(workbook.encode()!);
    final result = AccountDataService().parseDocument(
      name: '토스뱅크_거래내역.xlsx',
      bytes: bytes,
    );
    final categories = <String, String>{
      for (final transaction in result.transactions)
        transaction.merchant: transaction.category,
    };

    expect(result.transactions, hasLength(4));
    expect(categories['메가엠지씨커피 역삼점'], '카페');
    expect(categories['친구에게 보냄'], '이체');
    expect(categories['우리동네의원'], '의료');
    expect(categories['메가박스'], '여가');
  });

  test('recognizes common merchant categories', () {
    expect(AccountDataService.categorizeMerchant('올리브영 강남점'), '쇼핑');
    expect(AccountDataService.categorizeMerchant('한국전력 전기요금'), '생활');
    expect(AccountDataService.categorizeMerchant('교촌치킨'), '식비');
    expect(AccountDataService.categorizeMerchant('동네약국'), '의료');
  });
}
