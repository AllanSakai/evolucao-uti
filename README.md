# AuxiliarUTI

Aplicativo Flutter para apoiar a rotina de UTI com coleta estruturada de
evolucao por leito, resumo de plantao, documentos de alta, receitas,
medicamentos e protocolos.

## Recursos atuais

- Selecao da UTI e acompanhamento dos leitos do plantao.
- Coleta estruturada de dados clinicos e geracao de resumo para evolucao.
- Checklist leve de pendencias por leito, sem bloquear o fluxo.
- Resumo geral da ala com indicadores de VM, DVA, febre, diurese e BH.
- Exportacao local do plantao preenchido para copiar em um unico texto.
- Presets locais do formulario de evolucao para reaplicar modelos pessoais.
- Alta medica com atestado, receita, banco de medicamentos e protocolos.
- Sincronizacao opcional via Supabase para dados de plantao, medicamentos e
  protocolos.

## Experimento local

Os recursos de checklist, resumo da ala, exportacao do plantao e presets de
formulario foram adicionados como teste local. Eles nao exigem publicacao,
deploy, pull request ou alteracao no schema do Supabase.

Os presets de formulario ficam somente no armazenamento local do navegador ou
dispositivo usado pelo app.

## Executar

```bash
flutter pub get
flutter run
```

## Fluxo de visita

1. Abra a tela inicial e escolha a UTI do plantao.
2. Preencha ou continue a evolucao de cada leito.
3. Use o checklist leve para revisar pendencias importantes.
4. Gere o resumo do leito ou exporte todos os leitos preenchidos da ala.
5. Copie o texto gerado para usar no sistema desejado.

## Alta medica

A tela de alta concentra:

- Atestado de internacao.
- Receita medica.
- Banco de medicamentos.
- Protocolos de prescricoes.

## Sincronizacao com Supabase

A sincronizacao e opcional. Sem Supabase, o app continua salvando localmente no
aparelho ou navegador.

### 1. Criar projeto

1. Acesse https://supabase.com.
2. Crie uma conta.
3. Clique em New project.
4. Escolha uma senha forte para o banco.
5. Aguarde o projeto terminar de criar.

### 2. Criar tabela

1. No menu lateral do Supabase, abra SQL Editor.
2. Clique em New query.
3. Cole o conteudo de `supabase/schema.sql`.
4. Clique em Run.

### 3. Pegar as chaves

1. No Supabase, abra Project Settings.
2. Abra API.
3. Copie:
   - Project URL
   - anon public key

### 4. Rodar com sincronizacao

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=SUA_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=SUA_ANON_PUBLIC_KEY
```

Depois abra o botao de conta no canto superior direito do app, crie sua conta e
faca login.

## Privacidade

Evite salvar nome, prontuario, data de nascimento ou qualquer dado que
identifique o paciente. Use apenas UTI/leito e dados clinicos sem identificacao.

## Testes

```bash
flutter test
```
