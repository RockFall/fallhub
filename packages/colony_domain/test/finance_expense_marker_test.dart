import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  NotificationExtractInput input({
    String packageName = 'br.com.intermedium',
    String title = 'Compra aprovada',
    String text = 'R\$ 42,90 em RESTAURANTE X Cartão final 1234',
  }) {
    return NotificationExtractInput(
      packageName: packageName,
      title: title,
      text: text,
      postedAt: DateTime.utc(2026, 8, 20, 15),
    );
  }

  group('FinanceExpenseMarkerPolicy', () {
    test('parses one slice per line and drops blanks', () {
      final parsed = FinanceExpenseMarkerPolicy.parseField(
        ' Compra aprovada \n\nPix enviado\n',
      );
      expect(parsed.ok, isTrue);
      expect(parsed.slices, ['Compra aprovada', 'Pix enviado']);
      expect(
        FinanceExpenseMarkerPolicy.encodeField(parsed.slices),
        'Compra aprovada\nPix enviado',
      );
    });

    test('rejects a slice shorter than two characters', () {
      final parsed = FinanceExpenseMarkerPolicy.parseField('a\nPix');
      expect(parsed.ok, isFalse);
      expect(parsed.slices, ['Pix']);
    });

    test('matches ignoring case and accents', () {
      expect(
        FinanceExpenseMarkerPolicy.matches(
          'Compra no Cartão final 1234',
          const ['cartao'],
        ),
        isTrue,
      );
      expect(
        FinanceExpenseMarkerPolicy.matches(
          'Seu limite subiu',
          const ['compra aprovada'],
        ),
        isFalse,
      );
      expect(
        FinanceExpenseMarkerPolicy.matches('Compra aprovada', const []),
        isFalse,
      );
    });
  });

  group('FinanceNotificationExtractor expense slices', () {
    test('empty slices keep automatic purchase detection', () {
      final spend = FinanceNotificationExtractor.tryParse(input());
      expect(spend, isNotNull);
      expect(spend!.direction, TransactionDirection.outflow);
    });

    test('outflow is booked only when the notification contains the slice', () {
      const slices = ['compra aprovada'];
      final purchase = FinanceNotificationExtractor.tryParse(
        input(),
        expenseSlices: slices,
      );
      expect(purchase, isNotNull);
      expect(purchase!.direction, TransactionDirection.outflow);

      final limit = FinanceNotificationExtractor.tryParse(
        input(
          title: 'Limite',
          text: 'Seu limite agora é R\$ 5.000,00',
        ),
        expenseSlices: slices,
      );
      expect(limit, isNull);

      final pix = FinanceNotificationExtractor.tryParse(
        input(
          title: 'Pix enviado',
          text: 'Pix de R\$ 50,00 enviado para Maria Silva',
        ),
        expenseSlices: slices,
      );
      expect(pix, isNull);
    });

    test('inflow stays automatic even when slices are set', () {
      final received = FinanceNotificationExtractor.tryParse(
        input(
          title: 'Pix recebido',
          text: 'Você recebeu um Pix de R\$ 1.200,00',
        ),
        expenseSlices: const ['compra aprovada'],
      );
      expect(received, isNotNull);
      expect(received!.direction, TransactionDirection.inflow);
    });

    test('a matching slice books an expense the heuristics would miss', () {
      final spend = FinanceNotificationExtractor.tryParse(
        input(
          packageName: 'com.loja.qualquer',
          title: 'Aviso',
          text: 'Pedido confirmado no valor de R\$ 18,50',
        ),
        expenseSlices: const ['pedido confirmado'],
      );
      expect(spend, isNotNull);
      expect(spend!.amountMinor, 1850);
      expect(spend.direction, TransactionDirection.outflow);
    });
  });
}
