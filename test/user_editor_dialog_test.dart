import 'package:evolucao_uti/app_theme.dart';
import 'package:evolucao_uti/screens/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validadores identificam cada dado inválido do usuário', () {
    expect(UserFormValidators.name(''), 'Informe o nome completo.');
    expect(UserFormValidators.email('medico@'), 'Informe um e-mail válido.');
    expect(
      UserFormValidators.password('123', required: true),
      'A senha deve ter pelo menos 8 caracteres.',
    );
    expect(
      UserFormValidators.confirmPassword(
        'outra-senha',
        password: 'senha-valida',
        required: true,
      ),
      'As senhas não são iguais.',
    );
  });

  testWidgets('formulário destaca todos os campos obrigatórios',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PassagemUtiTheme.light,
        home: const Scaffold(body: UserEditorDialog()),
      ),
    );

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(find.text('Informe o nome completo.'), findsOneWidget);
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(find.text('Confirme a senha.'), findsOneWidget);
    expect(
      PassagemUtiTheme.light.inputDecorationTheme.errorBorder!.borderSide.color,
      PassagemUtiTheme.light.colorScheme.error,
    );
  });
}
