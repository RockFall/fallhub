import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FinanceNotificationExtractor', () {
    NotificationExtractInput input({
      String packageName = 'br.com.intermedium',
      String title = 'Compra aprovada',
      String text = 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
      DateTime? postedAt,
    }) {
      return NotificationExtractInput(
        packageName: packageName,
        title: title,
        text: text,
        postedAt: postedAt ?? DateTime.utc(2026, 8, 20, 15),
      );
    }

    test('parses Inter credit-card purchase', () {
      final spend = FinanceNotificationExtractor.tryParse(input());
      expect(spend, isNotNull);
      expect(spend!.amountMinor, 4290);
      expect(spend.direction, TransactionDirection.outflow);
      expect(spend.accountType, FinancialAccountType.creditCard);
      expect(spend.description, contains('RESTAURANTE'));
    });

    test('parses Pix sent as checking outflow', () {
      final spend = FinanceNotificationExtractor.tryParse(
        input(
          title: 'Pix enviado',
          text: 'Pix de R\$ 50,00 enviado para Maria Silva',
        ),
      );
      expect(spend, isNotNull);
      expect(spend!.amountMinor, 5000);
      expect(spend.direction, TransactionDirection.outflow);
      expect(spend.accountType, FinancialAccountType.checking);
    });

    test('parses Pix received as inflow', () {
      final spend = FinanceNotificationExtractor.tryParse(
        input(
          title: 'Pix recebido',
          text: 'Você recebeu um Pix de R\$ 1.200,00',
        ),
      );
      expect(spend!.direction, TransactionDirection.inflow);
      expect(spend.amountMinor, 120000);
      expect(spend.accountType, FinancialAccountType.checking);
    });

    test('ignores OTP codes', () {
      final kind = NotificationExtractionPipeline.classify(
        input(title: '123456', text: ''),
      );
      expect(kind, NotificationExtractorKind.ignored);
    });

    test('ignores non-financial noise', () {
      final spend = FinanceNotificationExtractor.tryParse(
        input(
          packageName: 'com.whatsapp',
          title: 'Oi',
          text: 'vamos jantar?',
        ),
      );
      expect(spend, isNull);
    });
  });

  group('InterStatementCodec', () {
    test('parses Inter semicolon CSV', () {
      const csv = '''
Extrato Conta Digital
Data Lançamento;Histórico;Descrição;Valor
01/08/2026;PIX ENVIADO;Maria;-50,00
02/08/2026;PIX RECEBIDO;João;1.200,00
''';
      final rows = InterStatementCodec.parse(csv, accountId: 'acc-1');
      expect(rows, hasLength(2));
      expect(rows.first.direction, TransactionDirection.outflow);
      expect(rows.first.amountMinor, 5000);
      expect(rows.last.direction, TransactionDirection.inflow);
      expect(rows.last.amountMinor, 120000);
    });

    test('parses OFX STMTTRN', () {
      const ofx = '''
OFXHEADER:100
<OFX>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260801120000[-3:BRT]
<TRNAMT>-31.90
<FITID>fit-1
<MEMO>UBER
</STMTTRN>
</OFX>
''';
      final rows = InterStatementCodec.parse(ofx, accountId: 'acc-1');
      expect(rows, hasLength(1));
      expect(rows.single.fingerprint, 'ofx:fit-1');
      expect(rows.single.amountMinor, 3190);
      expect(rows.single.direction, TransactionDirection.outflow);
      expect(rows.single.descriptionOriginal, 'UBER');
    });
  });
}
