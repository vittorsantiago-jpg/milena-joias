# Milena Joias · Sistema de Gestão de Pedidos

Sistema web para gestão de pedidos da Milena Joias, com painel kanban interno e portal do cliente.

## Estrutura

```
milena-joias/
└── index.html   ← arquivo único do sistema (front-end completo)
```

## Como fazer o deploy no Netlify

1. Acesse [netlify.com](https://netlify.com) e faça login
2. Clique em **Add new site → Deploy manually**
3. Arraste a pasta `milena-joias` para a área de drop
4. Pronto! O site vai ao ar em segundos

## Via GitHub (recomendado para atualizações fáceis)

```bash
git init
git add .
git commit -m "primeiro commit"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/milena-joias.git
git push -u origin main
```

Depois conecte o repositório no Netlify em **Add new site → Import from Git**.

## Configuração do Supabase

Após o deploy, abra o `index.html` e adicione suas credenciais do Supabase:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_ANON_KEY = 'sua-chave-anon-aqui';
```

Consulte o **Guia de Deploy** para o passo a passo completo.
