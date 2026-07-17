# Publicar o AuxiliarUTI na Vercel

O Flutter Web e compilado e publicado pela integracao direta entre a Vercel e o
GitHub. Pushes na branch `main` atualizam producao; pull requests recebem um
deploy de preview.

## 1. Vincular o projeto a Vercel

No painel da Vercel, importe o repositorio `AllanSakai/evolucao-uti` e confirme
que a branch de producao e `main`.

Para vincular tambem a pasta local, use na raiz do repositorio, com a Vercel CLI
autenticada:

```powershell
vercel link
```

Crie ou selecione o projeto `evolucao-uti`. O arquivo local
`.vercel/project.json` sera criado, mas nao deve ser enviado ao Git.

## 2. Configurar as variaveis da aplicacao na Vercel

No projeto da Vercel, abra `Settings` > `Environment Variables` e cadastre:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Marque `Production` e `Preview` para cada variavel. Opcionalmente, cadastre
`ADMIN_EMAIL`; se omitida, a compilacao usa `allansakai@gmail.com`.

Enquanto producao e preview usarem o mesmo projeto Supabase, nao use dados reais
para testar um pull request. O ideal e configurar futuramente um projeto
Supabase separado para previews.

Depois de alterar variaveis, e necessario fazer um novo deploy, pois o Flutter
as incorpora no JavaScript durante a compilacao.

## 3. Publicar

Ao abrir ou atualizar um pull request, a integracao da Vercel cria uma preview.
Depois do merge na `main`, a mesma integracao cria o deploy de producao. O
comando de build e o diretorio publicado estao definidos em `vercel.json`.

## 4. Automatizar migrations do Supabase

No GitHub, abra `Settings` > `Secrets and variables` > `Actions` e confirme os
secrets:

```text
SUPABASE_ACCESS_TOKEN
SUPABASE_PROJECT_ID
```

O workflow `.github/workflows/deploy-supabase-migrations.yml` e executado quando
uma migration entra na branch `main`. Primeiro ele mostra as migrations
pendentes com `supabase db push --dry-run` e, se a verificacao funcionar, aplica
somente as migrations ainda nao registradas no banco.

O workflow usa concorrencia exclusiva e nao cancela uma execucao em andamento,
evitando duas publicacoes simultaneas no mesmo banco.

Depois de adotar esse fluxo, nao altere o schema de producao diretamente pelo
SQL Editor ou Table Editor. Crie cada alteracao com:

```bash
supabase migration new descricao_da_alteracao
```

## 5. Configurar o Supabase Auth

Depois que a Vercel fornecer o dominio de producao, abra no Supabase
`Authentication` > `URL Configuration`:

1. Defina `Site URL` como `https://SEU-PROJETO.vercel.app`.
2. Adicione a mesma URL em `Redirect URLs`.
3. Para previews da equipe atual, adicione
   `https://*-pixel-apps.vercel.app/**` em `Redirect URLs`.
4. Mantenha tambem as URLs locais usadas durante o desenvolvimento.

Exemplo:

```text
http://127.0.0.1:53123/
http://localhost:53123/
https://SEU-PROJETO.vercel.app/
https://*-pixel-apps.vercel.app/**
```

Use sempre a URL exata em producao; o curinga deve ficar restrito aos previews.

## 6. Desativar o GitHub Pages

O workflow antigo foi removido. Se o Pages ainda estiver ativo no repositorio,
abra `Settings` > `Pages` e desative a publicacao depois de confirmar o deploy
na Vercel.

## Uso no celular

Abra a URL da Vercel no Safari ou Chrome. Para instalar como atalho:

- iPhone/Safari: Compartilhar > Adicionar a Tela de Inicio.
- Android/Chrome: menu > Adicionar a tela inicial.
