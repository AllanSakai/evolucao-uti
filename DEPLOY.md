# Publicar o EvoluçãoUTI

Este projeto está preparado para publicar o Flutter Web no GitHub Pages e sincronizar os dados pelo Supabase.

## 1. Criar o repositório no GitHub

1. Acesse https://github.com/new
2. Nome sugerido: `evolucao-uti`
3. Pode ser privado ou público.
4. Não marque para criar README, `.gitignore` ou license, porque o projeto já tem esses arquivos.
5. Crie o repositório.

## 2. Enviar o projeto

No PowerShell, dentro da pasta do projeto:

```powershell
git remote add origin https://github.com/SEU_USUARIO/evolucao-uti.git
git branch -M main
git push -u origin main
```

## 3. Configurar secrets do Supabase no GitHub

No repositório GitHub:

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

## 4. Criar o usuario administrador

No Supabase, abra `Authentication` > `Users` e confirme que o usuario
`allansakai@gmail.com` esta cadastrado e com o e-mail confirmado. Esse usuario
entra no site usando o nome `admin` e tem acesso completo para adicionar, editar
e remover dados.

## 5. Ativar GitHub Pages

No repositório GitHub:

1. Settings
2. Pages
3. Em Source, escolha `GitHub Actions`
4. Salve.

Depois do primeiro push, o workflow `.github/workflows/deploy-pages.yml` vai compilar e publicar o site.

## 6. Configurar URLs no Supabase Auth

No Supabase:

1. Authentication
2. URL Configuration
3. Site URL: a URL publicada no GitHub Pages, por exemplo:

```text
https://SEU_USUARIO.github.io/evolucao-uti/
```

4. Em Redirect URLs, adicione também:

```text
http://127.0.0.1:53123/
http://localhost:53123/
https://SEU_USUARIO.github.io/evolucao-uti/
```

Se o link de confirmação de e-mail abrir uma página 404 do GitHub, confira se o
`Site URL` e o Redirect URL principal estão exatamente com o caminho do projeto:

```text
https://SEU_USUARIO.github.io/evolucao-uti/
```

O `/evolucao-uti/` no final é obrigatório para GitHub Pages de repositório.

## 7. Usar no celular

Abra a URL do GitHub Pages no Safari/Chrome do celular, entre na sua conta e use normalmente.

Se quiser instalar como atalho:

- iPhone/Safari: compartilhar -> Adicionar à Tela de Início
- Android/Chrome: menu -> Adicionar à tela inicial
