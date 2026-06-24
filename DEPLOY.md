# Publicar o EvolucaoUTI

Este projeto esta preparado para publicar o Flutter Web no GitHub Pages e sincronizar os dados pelo Supabase.

## 1. Criar o repositorio no GitHub

1. Acesse https://github.com/new
2. Nome sugerido: `evolucao-uti`
3. Pode ser privado ou publico.
4. Nao marque para criar README, `.gitignore` ou license, porque o projeto ja tem esses arquivos.
5. Crie o repositorio.

## 2. Enviar o projeto

No PowerShell, dentro da pasta do projeto:

```powershell
git remote add origin https://github.com/SEU_USUARIO/evolucao-uti.git
git branch -M main
git push -u origin main
```

## 3. Configurar secrets do Supabase no GitHub

No repositorio GitHub:

1. Settings
2. Secrets and variables
3. Actions
4. New repository secret

Crie duas secrets:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Use os valores do Supabase:

- Project URL
- anon/public key

## 4. Ativar GitHub Pages

No repositorio GitHub:

1. Settings
2. Pages
3. Em Source, escolha `GitHub Actions`
4. Salve.

Depois do primeiro push, o workflow `.github/workflows/deploy-pages.yml` vai compilar e publicar o site.

## 5. Configurar URLs no Supabase Auth

No Supabase:

1. Authentication
2. URL Configuration
3. Site URL: a URL publicada no GitHub Pages, por exemplo:

```text
https://SEU_USUARIO.github.io/evolucao-uti/
```

4. Em Redirect URLs, adicione tambem:

```text
http://127.0.0.1:53123/
http://localhost:53123/
https://SEU_USUARIO.github.io/evolucao-uti/
```

Se o link de confirmacao de e-mail abrir uma pagina 404 do GitHub, confira se o
`Site URL` e o Redirect URL principal estao exatamente com o caminho do projeto:

```text
https://SEU_USUARIO.github.io/evolucao-uti/
```

O `/evolucao-uti/` no final e obrigatorio para GitHub Pages de repositorio.

## 6. Usar no celular

Abra a URL do GitHub Pages no Safari/Chrome do celular, entre na sua conta e use normalmente.

Se quiser instalar como atalho:

- iPhone/Safari: compartilhar -> Adicionar a Tela de Inicio
- Android/Chrome: menu -> Adicionar a tela inicial
