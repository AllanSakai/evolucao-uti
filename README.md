# EvoluçãoUTI

Aplicativo Flutter para coletar dados estruturados de visita/evolução em UTI e gerar um resumo em caixa alta para copiar e usar no GPT.

## Executar

```bash
flutter pub get
flutter run
```

## Fluxo atual

1. Selecione a UTI.
2. Preencha os dados do leito durante a visita.
3. Gere o resumo estruturado.
4. Copie o resumo e cole no GPT para redigir a evolução final.

## Sincronização com Supabase

A sincronização é opcional. Sem Supabase, o app continua salvando localmente no aparelho.

### 1. Criar projeto

1. Acesse https://supabase.com.
2. Crie uma conta.
3. Clique em New project.
4. Escolha uma senha forte para o banco.
5. Aguarde o projeto terminar de criar.

### 2. Criar tabela

1. No menu lateral do Supabase, abra SQL Editor.
2. Clique em New query.
3. Cole o conteúdo de `supabase/schema.sql`.
4. Clique em Run.

### 3. Pegar as chaves

1. No Supabase, abra Project Settings.
2. Abra API.
3. Copie:
   - Project URL
   - anon public key

### 4. Rodar o app com sincronização

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=SUA_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=SUA_ANON_PUBLIC_KEY
```

Depois abra o botão de conta no canto superior direito do app, crie sua conta e faça login.

### Observação de privacidade

Evite salvar nome, prontuário, data de nascimento ou qualquer dado que identifique o paciente. Use apenas UTI/leito e dados clínicos sem identificação.

## Testes

```bash
flutter test
```
